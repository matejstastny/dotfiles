package main

import (
	"context"
	"embed"
	"encoding/json"
	"errors"
	"fmt"
	"io/fs"
	"log"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"os/signal"
	"strings"
	"syscall"
	"time"
)

//go:embed all:dist
var embedded embed.FS

type server struct {
	cfg    config
	store  *store
	runner *runner
	probes *probeCache
}

func main() {
	log.SetFlags(log.Ldate | log.Ltime)
	cfg := loadConfig()

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	st, err := newStore(cfg)
	if err != nil {
		log.Fatalf("cache dir %s: %v", cfg.cacheDir, err)
	}

	s := &server{cfg: cfg, store: st, runner: newRunner(ctx, cfg, st), probes: newProbeCache()}

	srv := &http.Server{
		Addr:              cfg.listen,
		Handler:           s.routes(),
		ReadHeaderTimeout: 15 * time.Second,
	}

	go func() {
		log.Printf("listening on %s, cache %s in %s, %d workers", cfg.listen, human(cfg.cacheLimit), cfg.cacheDir, cfg.workers)
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
	mux.HandleFunc("POST /api/probe", s.handleProbe)
	mux.HandleFunc("POST /api/jobs", s.handleCreateJob)
	mux.HandleFunc("GET /api/jobs/{id}/events", s.handleEvents)
	mux.HandleFunc("GET /api/files", s.handleFiles)
	mux.HandleFunc("GET /api/files/{id}/download", s.handleDownload)
	mux.HandleFunc("DELETE /api/files/{id}", s.handleDrop)
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
		// forever while the pages themselves must always be revalidated
		if strings.HasPrefix(r.URL.Path, "/_astro/") || strings.HasPrefix(r.URL.Path, "/fonts/") {
			w.Header().Set("Cache-Control", "public, max-age=31536000, immutable")
		} else {
			w.Header().Set("Cache-Control", "no-cache")
		}
		files.ServeHTTP(w, r)
	})
}

type probeResponse struct {
	URL      string  `json:"url"`
	Title    string  `json:"title"`
	Uploader string  `json:"uploader,omitempty"`
	Duration string  `json:"duration,omitempty"`
	Seconds  float64 `json:"seconds,omitempty"`
	Source   string  `json:"source,omitempty"`
	Heights  []int   `json:"heights"`
}

func (s *server) handleProbe(w http.ResponseWriter, r *http.Request) {
	var body struct {
		URL string `json:"url"`
	}
	if err := readJSON(w, r, &body); err != nil {
		fail(w, http.StatusBadRequest, err)
		return
	}

	target, err := cleanURL(body.URL)
	if err != nil {
		fail(w, http.StatusBadRequest, err)
		return
	}

	meta, err := s.probes.get(r.Context(), s.cfg, target)
	if err != nil {
		fail(w, http.StatusBadGateway, err)
		return
	}

	writeJSON(w, http.StatusOK, probeResponse{
		URL:      target,
		Title:    meta.Title,
		Uploader: meta.author(),
		Duration: durationLabel(meta.Duration),
		Seconds:  meta.Duration,
		Source:   meta.Extractor,
		Heights:  meta.heights(),
	})
}

var (
	allowedBitrates = map[int]bool{128: true, 192: true, 256: true, 320: true}
	allowedModes    = map[string]bool{"cache": true, "library": true, "both": true}
)

func (s *server) handleCreateJob(w http.ResponseWriter, r *http.Request) {
	var req jobRequest
	if err := readJSON(w, r, &req); err != nil {
		fail(w, http.StatusBadRequest, err)
		return
	}

	target, err := cleanURL(req.URL)
	if err != nil {
		fail(w, http.StatusBadRequest, err)
		return
	}
	req.URL = target

	if req.Format != "mp4" && req.Format != "mp3" {
		fail(w, http.StatusBadRequest, errors.New("format has to be mp4 or mp3"))
		return
	}
	// the picker offers whatever the video actually has, which is rarely a round
	// number, so this only rules out nonsense
	if req.Format == "mp4" && (req.Height < 0 || req.Height > 4320) {
		fail(w, http.StatusBadRequest, errors.New("that is not a sane resolution"))
		return
	}
	if req.Format == "mp3" {
		if !allowedBitrates[req.Bitrate] {
			fail(w, http.StatusBadRequest, errors.New("that is not a bitrate on offer"))
			return
		}
		req.Height = 0
	}
	if req.Mode == "" {
		req.Mode = "cache"
	}
	if !allowedModes[req.Mode] {
		fail(w, http.StatusBadRequest, errors.New("that is not a destination on offer"))
		return
	}

	job, err := s.runner.submit(req)
	if err != nil {
		fail(w, http.StatusServiceUnavailable, err)
		return
	}

	writeJSON(w, http.StatusAccepted, map[string]string{"id": job.id})
}

func (s *server) handleEvents(w http.ResponseWriter, r *http.Request) {
	job, ok := s.runner.job(r.PathValue("id"))
	if !ok {
		fail(w, http.StatusNotFound, errors.New("no such download"))
		return
	}

	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	w.Header().Set("X-Accel-Buffering", "no")

	flush := http.NewResponseController(w)
	sentFinal := false
	send := func(ev event) error {
		raw, err := json.Marshal(ev)
		if err != nil {
			return err
		}
		if ev.Stage == "done" || ev.Stage == "error" {
			sentFinal = true
		}
		if _, err := fmt.Fprintf(w, "data: %s\n\n", raw); err != nil {
			return err
		}
		return flush.Flush()
	}

	snapshot, finished := job.snapshot()
	if err := send(snapshot); err != nil || finished {
		return
	}

	updates, live := job.subscribe()
	if !live {
		final, _ := job.snapshot()
		send(final)
		return
	}
	defer job.unsubscribe(updates)

	ping := time.NewTicker(20 * time.Second)
	defer ping.Stop()

	for {
		select {
		case <-r.Context().Done():
			return
		case <-ping.C:
			if _, err := fmt.Fprint(w, ": ping\n\n"); err != nil {
				return
			}
			if flush.Flush() != nil {
				return
			}
		case ev, open := <-updates:
			if !open {
				// the job ended; the terminal event may have been dropped if this
				// client was slow, so fall back to the stored snapshot
				if !sentFinal {
					final, _ := job.snapshot()
					send(final)
				}
				return
			}
			if err := send(ev); err != nil {
				return
			}
		}
	}
}

func (s *server) handleFiles(w http.ResponseWriter, r *http.Request) {
	used, limit := s.store.usage()
	writeJSON(w, http.StatusOK, map[string]any{
		"files": s.store.list(),
		"cache": map[string]int64{"used": used, "limit": limit},
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

	path, err := e.path()
	if err != nil {
		fail(w, http.StatusGone, err)
		return
	}

	w.Header().Set("Content-Type", contentType(e.Format))
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

func cleanURL(raw string) (string, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return "", errors.New("paste a link first")
	}
	if len(raw) > 2048 {
		return "", errors.New("that link is absurdly long")
	}

	parsed, err := url.Parse(raw)
	if err != nil {
		return "", errors.New("that does not parse as a link")
	}
	if parsed.Scheme != "http" && parsed.Scheme != "https" {
		return "", errors.New("only http and https links work")
	}
	if parsed.Host == "" {
		return "", errors.New("that link has no host")
	}
	return parsed.String(), nil
}

func contentType(format string) string {
	if format == "mp3" {
		return "audio/mpeg"
	}
	return "video/mp4"
}

// disposition ships both a plain ascii fallback and the real utf-8 name, since
// video titles are full of characters a bare filename= cannot carry
func disposition(name string) string {
	ascii := strings.Map(func(r rune) rune {
		if r < 32 || r > 126 || r == '"' || r == '\\' {
			return '_'
		}
		return r
	}, name)
	return fmt.Sprintf("attachment; filename=%q; filename*=UTF-8''%s", ascii, url.PathEscape(name))
}

func readJSON(w http.ResponseWriter, r *http.Request, into any) error {
	decoder := json.NewDecoder(http.MaxBytesReader(w, r.Body, 8<<10))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(into); err != nil {
		return errors.New("could not read that request")
	}
	return nil
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(body)
}

func fail(w http.ResponseWriter, status int, err error) {
	writeJSON(w, status, map[string]string{"error": err.Error()})
}

// command wires yt-dlp up so a service restart stops it politely instead of
// leaving half a file and a stuck ffmpeg behind
func command(ctx context.Context, name string, args ...string) *exec.Cmd {
	cmd := exec.CommandContext(ctx, name, args...)
	cmd.Cancel = func() error { return cmd.Process.Signal(syscall.SIGTERM) }
	cmd.WaitDelay = 10 * time.Second
	cmd.Env = append(os.Environ(), "LC_ALL=C.UTF-8")
	return cmd
}
