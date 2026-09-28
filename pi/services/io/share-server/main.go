package main

import (
	"context"
	"embed"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"log"
	"mime/multipart"
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"path/filepath"
	"strings"
	"syscall"
	"time"
)

//go:embed all:dist
var embedded embed.FS

type server struct {
	cfg   config
	store *store
}

func main() {
	log.SetFlags(log.Ldate | log.Ltime)
	cfg := loadConfig()

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	st, err := newStore(cfg)
	if err != nil {
		log.Fatalf("share dir %s: %v", cfg.dir, err)
	}

	s := &server{cfg: cfg, store: st}

	srv := &http.Server{
		Addr:              cfg.listen,
		Handler:           s.routes(),
		ReadHeaderTimeout: 15 * time.Second,
	}

	go func() {
		log.Printf("listening on %s, up to %d files in %s, %s max each", cfg.listen, cfg.maxFiles, cfg.dir, human(cfg.maxFileSize))
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("listen: %v", err)
		}
	}()

	<-ctx.Done()
	log.Print("shutting down")

	shutdown, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	srv.Shutdown(shutdown)
}

func (s *server) routes() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("POST /api/files", s.handleUpload)
	mux.HandleFunc("GET /api/files", s.handleList)
	mux.HandleFunc("DELETE /api/files/{id}", s.handleDrop)
	mux.HandleFunc("GET /dl/{id}/{name}", s.handleDownload)
	mux.Handle("GET /", s.static())
	return mux
}

func (s *server) static() http.Handler {
	dist, err := fs.Sub(embedded, "dist")
	if err != nil {
		log.Fatalf("embedded ui: %v", err)
	}
	files := http.FileServer(http.FS(dist))

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// astro fingerprints everything under _astro, so those can be pinned
		// forever while the page itself must always be revalidated
		if strings.HasPrefix(r.URL.Path, "/_astro/") || strings.HasPrefix(r.URL.Path, "/fonts/") {
			w.Header().Set("Cache-Control", "public, max-age=31536000, immutable")
		} else {
			w.Header().Set("Cache-Control", "no-cache")
		}
		files.ServeHTTP(w, r)
	})
}

func (s *server) handleUpload(w http.ResponseWriter, r *http.Request) {
	// a little slack over the configured cap for the multipart boilerplate
	// itself, so the real limit error comes from the copy below, not this wrapper
	r.Body = http.MaxBytesReader(w, r.Body, s.cfg.maxFileSize+1<<20)

	reader, err := r.MultipartReader()
	if err != nil {
		fail(w, http.StatusBadRequest, errors.New("expected a multipart upload"))
		return
	}

	var part *multipart.Part
	for {
		p, err := reader.NextPart()
		if errors.Is(err, io.EOF) {
			fail(w, http.StatusBadRequest, errors.New("no file in that upload"))
			return
		}
		if err != nil {
			fail(w, http.StatusBadRequest, errors.New("could not read that upload"))
			return
		}
		if p.FormName() == "file" {
			part = p
			break
		}
		p.Close()
	}

	name := sanitizeName(part.FileName())
	if name == "" {
		fail(w, http.StatusBadRequest, errors.New("that file has no usable name"))
		return
	}

	id := newID()
	dir := filepath.Join(s.cfg.dir, id)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		fail(w, http.StatusInternalServerError, err)
		return
	}

	out, err := os.OpenFile(filepath.Join(dir, name), os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o644)
	if err != nil {
		os.RemoveAll(dir)
		fail(w, http.StatusInternalServerError, err)
		return
	}

	written, err := io.Copy(out, part)
	out.Close()
	if err != nil {
		os.RemoveAll(dir)
		if err.Error() == "http: request body too large" {
			fail(w, http.StatusRequestEntityTooLarge, fmt.Errorf("that is over the %s limit", human(s.cfg.maxFileSize)))
			return
		}
		fail(w, http.StatusBadRequest, errors.New("upload did not finish"))
		return
	}

	e := &entry{ID: id, Name: name, Size: written, Created: time.Now()}
	if err := s.store.add(e); err != nil {
		os.RemoveAll(dir)
		fail(w, http.StatusInternalServerError, err)
		return
	}
	s.store.enforceLimit(id)

	writeJSON(w, http.StatusCreated, e)
}

func (s *server) handleList(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"files": s.store.list(),
		"limit": s.cfg.maxFiles,
	})
}

func (s *server) handleDownload(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if !validID(id) {
		fail(w, http.StatusBadRequest, errors.New("that is not a file id"))
		return
	}

	e, ok := s.store.get(id)
	if !ok {
		fail(w, http.StatusNotFound, errors.New("no such file"))
		return
	}

	path := e.path(s.cfg.dir)
	if _, err := os.Stat(path); err != nil {
		fail(w, http.StatusGone, errors.New("the file is gone from disk"))
		return
	}

	w.Header().Set("Content-Disposition", disposition(e.Name))
	http.ServeFile(w, r, path)
}

func (s *server) handleDrop(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if !validID(id) {
		fail(w, http.StatusBadRequest, errors.New("that is not a file id"))
		return
	}
	if err := s.store.drop(id); err != nil {
		fail(w, http.StatusNotFound, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// sanitizeName keeps the upload's own name for display and the download
// filename, but never lets it escape its own upload directory
func sanitizeName(name string) string {
	name = filepath.Base(strings.TrimSpace(name))
	if name == "." || name == ".." || name == "" || name == string(filepath.Separator) {
		return ""
	}
	return name
}

// disposition ships both a plain ascii fallback and the real utf-8 name, since
// a shared file's name is full of characters a bare filename= cannot carry
func disposition(name string) string {
	ascii := strings.Map(func(r rune) rune {
		if r < 32 || r > 126 || r == '"' || r == '\\' {
			return '_'
		}
		return r
	}, name)
	return fmt.Sprintf("attachment; filename=%q; filename*=UTF-8''%s", ascii, url.PathEscape(name))
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(body)
}

func fail(w http.ResponseWriter, status int, err error) {
	writeJSON(w, status, map[string]string{"error": err.Error()})
}
