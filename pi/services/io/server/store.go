package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"sort"
	"sync"
	"time"
)

type entry struct {
	ID          string    `json:"id"`
	Title       string    `json:"title"`
	Uploader    string    `json:"uploader,omitempty"`
	URL         string    `json:"url"`
	Thumbnail   string    `json:"thumbnail,omitempty"`
	Duration    float64   `json:"duration,omitempty"`
	Format      string    `json:"format"`
	Quality     string    `json:"quality,omitempty"`
	Name        string    `json:"name"`
	Size        int64     `json:"size"`
	Created     time.Time `json:"created"`
	CachePath   string    `json:"cachePath,omitempty"`
	ArchivePath string    `json:"archivePath,omitempty"`
}

// publicEntry is what the browser is allowed to see: server side paths stay
// server side, apart from the library one, which is the point of library mode
type publicEntry struct {
	ID       string    `json:"id"`
	Title    string    `json:"title"`
	Uploader string    `json:"uploader,omitempty"`
	URL      string    `json:"url"`
	Format   string    `json:"format"`
	Quality  string    `json:"quality,omitempty"`
	Name     string    `json:"name"`
	Size     int64     `json:"size"`
	Duration float64   `json:"duration,omitempty"`
	Created  time.Time `json:"created"`
	Cached   bool      `json:"cached"`
	Library  bool      `json:"library"`
	Path     string    `json:"path,omitempty"`
}

func (e entry) public() publicEntry {
	return publicEntry{
		ID:       e.ID,
		Title:    e.Title,
		Uploader: e.Uploader,
		URL:      e.URL,
		Format:   e.Format,
		Quality:  e.Quality,
		Name:     e.Name,
		Size:     e.Size,
		Duration: e.Duration,
		Created:  e.Created,
		Cached:   e.CachePath != "",
		Library:  e.ArchivePath != "",
		Path:     e.ArchivePath,
	}
}

type store struct {
	cfg     config
	mu      sync.Mutex
	entries map[string]*entry
}

func newStore(cfg config) (*store, error) {
	s := &store{cfg: cfg, entries: map[string]*entry{}}
	if err := os.MkdirAll(cfg.cacheDir, 0o755); err != nil {
		return nil, err
	}
	if err := s.load(); err != nil {
		return nil, err
	}
	return s, nil
}

func (s *store) metaPath(id string) string {
	return filepath.Join(s.cfg.cacheDir, id, "meta.json")
}

// load rebuilds the index from the job dirs, which are the only source of truth.
// a dir with no meta.json is a job that died mid-flight, so it gets swept.
func (s *store) load() error {
	dirs, err := os.ReadDir(s.cfg.cacheDir)
	if err != nil {
		return err
	}

	for _, d := range dirs {
		if !d.IsDir() || !validID(d.Name()) {
			continue
		}
		dir := filepath.Join(s.cfg.cacheDir, d.Name())

		raw, err := os.ReadFile(filepath.Join(dir, "meta.json"))
		if err != nil {
			log.Printf("sweeping incomplete job dir %s", d.Name())
			os.RemoveAll(dir)
			continue
		}

		var e entry
		if err := json.Unmarshal(raw, &e); err != nil || e.ID != d.Name() {
			log.Printf("sweeping unreadable job dir %s", d.Name())
			os.RemoveAll(dir)
			continue
		}

		if e.CachePath != "" {
			if _, err := os.Stat(e.CachePath); err != nil {
				e.CachePath = ""
			}
		}
		if e.ArchivePath != "" {
			if _, err := os.Stat(e.ArchivePath); err != nil {
				e.ArchivePath = ""
			}
		}
		if e.CachePath == "" && e.ArchivePath == "" {
			os.RemoveAll(dir)
			continue
		}

		s.entries[e.ID] = &e
	}

	log.Printf("cache: %d entries, %s of %s used", len(s.entries), human(s.used()), human(s.cfg.cacheLimit))
	return nil
}

func (s *store) save(e *entry) error {
	dir := filepath.Join(s.cfg.cacheDir, e.ID)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	raw, err := json.MarshalIndent(e, "", "  ")
	if err != nil {
		return err
	}
	tmp := filepath.Join(dir, "meta.json.tmp")
	if err := os.WriteFile(tmp, raw, 0o644); err != nil {
		return err
	}
	return os.Rename(tmp, s.metaPath(e.ID))
}

func (s *store) add(e *entry) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if err := s.save(e); err != nil {
		return err
	}
	s.entries[e.ID] = e
	return nil
}

func (s *store) get(id string) (entry, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	e, ok := s.entries[id]
	if !ok {
		return entry{}, false
	}
	return *e, true
}

func (s *store) list() []publicEntry {
	s.mu.Lock()
	defer s.mu.Unlock()

	out := make([]publicEntry, 0, len(s.entries))
	for _, e := range s.entries {
		out = append(out, e.public())
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Created.After(out[j].Created) })
	return out
}

// used counts only cached copies: library files live on the big disk and are
// never evicted, so they must not push the cache over its cap
func (s *store) used() int64 {
	var total int64
	for _, e := range s.entries {
		if e.CachePath != "" {
			total += e.Size
		}
	}
	return total
}

func (s *store) usage() (int64, int64) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.used(), s.cfg.cacheLimit
}

// drop removes the cached copy. a library copy, if any, is deliberately left
// alone, and the entry stays listed so you can still reach the file.
func (s *store) drop(id string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.dropLocked(id)
}

func (s *store) dropLocked(id string) error {
	e, ok := s.entries[id]
	if !ok {
		return errors.New("no such file")
	}

	if e.CachePath != "" {
		if err := os.Remove(e.CachePath); err != nil && !os.IsNotExist(err) {
			return err
		}
		e.CachePath = ""
	}

	if e.ArchivePath == "" {
		delete(s.entries, id)
		return os.RemoveAll(filepath.Join(s.cfg.cacheDir, id))
	}
	return s.save(e)
}

// enforceLimit evicts oldest first until the cache fits. keep is the job that
// just finished, so a single oversized download is never deleted out from under
// the browser that is about to fetch it.
func (s *store) enforceLimit(keep string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	for s.used() > s.cfg.cacheLimit {
		var victim *entry
		for _, e := range s.entries {
			if e.ID == keep || e.CachePath == "" {
				continue
			}
			if victim == nil || e.Created.Before(victim.Created) {
				victim = e
			}
		}
		if victim == nil {
			return
		}
		log.Printf("cache: evicting %q (%s)", victim.Name, human(victim.Size))
		if err := s.dropLocked(victim.ID); err != nil {
			log.Printf("cache: eviction failed for %s: %v", victim.ID, err)
			return
		}
	}
}

// path picks whichever copy of the file still exists
func (e entry) path() (string, error) {
	for _, p := range []string{e.CachePath, e.ArchivePath} {
		if p == "" {
			continue
		}
		if _, err := os.Stat(p); err == nil {
			return p, nil
		}
	}
	return "", errors.New("the file is gone from disk")
}

// place puts the finished download where the request asked for. cache and
// library are on the same filesystem on io, so "both" is a hardlink and costs
// nothing; the copy fallback is there in case that ever stops being true.
func place(src, dstDir, name string, keepCache bool) (string, error) {
	if err := os.MkdirAll(dstDir, 0o775); err != nil {
		return "", err
	}
	dst := uniquePath(dstDir, name)

	if keepCache {
		if err := os.Link(src, dst); err == nil {
			return dst, nil
		}
		if err := copyFile(src, dst); err != nil {
			return "", err
		}
		return dst, nil
	}

	if err := os.Rename(src, dst); err == nil {
		return dst, nil
	}
	if err := copyFile(src, dst); err != nil {
		return "", err
	}
	return dst, os.Remove(src)
}

func uniquePath(dir, name string) string {
	dst := filepath.Join(dir, name)
	if _, err := os.Stat(dst); err != nil {
		return dst
	}
	ext := filepath.Ext(name)
	stem := name[:len(name)-len(ext)]
	for i := 2; ; i++ {
		candidate := filepath.Join(dir, fmt.Sprintf("%s (%d)%s", stem, i, ext))
		if _, err := os.Stat(candidate); err != nil {
			return candidate
		}
	}
}

func copyFile(src, dst string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()

	out, err := os.OpenFile(dst, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o664)
	if err != nil {
		return err
	}
	if _, err := io.Copy(out, in); err != nil {
		out.Close()
		os.Remove(dst)
		return err
	}
	return out.Close()
}

func human(n int64) string {
	const unit = 1000
	if n < unit {
		return fmt.Sprintf("%d B", n)
	}
	value := float64(n)
	units := []string{"kB", "MB", "GB", "TB"}
	for _, u := range units {
		value /= unit
		if value < unit {
			return fmt.Sprintf("%.1f %s", value, u)
		}
	}
	return fmt.Sprintf("%.1f PB", value/unit)
}
