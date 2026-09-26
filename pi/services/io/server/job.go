package main

import (
	"bufio"
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"
)

type jobRequest struct {
	URL          string `json:"url"`
	Format       string `json:"format"`
	Height       int    `json:"height"`
	Bitrate      int    `json:"bitrate"`
	Mode         string `json:"mode"`
	Metadata     bool   `json:"metadata"`
	Thumbnail    bool   `json:"thumbnail"`
	SponsorBlock bool   `json:"sponsorblock"`
}

type event struct {
	Stage   string  `json:"stage"`
	Label   string  `json:"label,omitempty"`
	Percent float64 `json:"percent"`
	Speed   float64 `json:"speed,omitempty"`
	ETA     float64 `json:"eta,omitempty"`
	Total   int64   `json:"total,omitempty"`
	Message string  `json:"message,omitempty"`

	Entry    *publicEntry `json:"entry,omitempty"`
	terminal bool
}

type job struct {
	id  string
	req jobRequest

	mu         sync.Mutex
	subs       map[chan event]struct{}
	last       event
	finished   bool
	finishedAt time.Time
}

func (j *job) publish(ev event) {
	j.mu.Lock()
	defer j.mu.Unlock()

	j.last = ev
	if ev.terminal {
		j.finished = true
		j.finishedAt = time.Now()
	}

	for ch := range j.subs {
		select {
		case ch <- ev:
		default:
		}
	}

	// closing wakes every reader even if its buffer was full, and the handler
	// falls back to the stored snapshot, so a terminal event can never be lost
	if ev.terminal {
		for ch := range j.subs {
			close(ch)
		}
		j.subs = map[chan event]struct{}{}
	}
}

func (j *job) snapshot() (event, bool) {
	j.mu.Lock()
	defer j.mu.Unlock()
	return j.last, j.finished
}

func (j *job) subscribe() (chan event, bool) {
	j.mu.Lock()
	defer j.mu.Unlock()
	if j.finished {
		return nil, false
	}
	ch := make(chan event, 32)
	j.subs[ch] = struct{}{}
	return ch, true
}

func (j *job) unsubscribe(ch chan event) {
	j.mu.Lock()
	defer j.mu.Unlock()
	delete(j.subs, ch)
}

type runner struct {
	cfg   config
	store *store
	queue chan *job

	mu   sync.Mutex
	jobs map[string]*job
}

func newRunner(ctx context.Context, cfg config, s *store) *runner {
	r := &runner{
		cfg:   cfg,
		store: s,
		queue: make(chan *job, 64),
		jobs:  map[string]*job{},
	}
	for i := 0; i < cfg.workers; i++ {
		go r.worker(ctx)
	}
	go r.reap(ctx)
	return r
}

func (r *runner) worker(ctx context.Context) {
	for {
		select {
		case <-ctx.Done():
			return
		case j := <-r.queue:
			r.run(ctx, j)
		}
	}
}

// reap forgets finished jobs so a long uptime does not accumulate them. the
// files themselves live in the store, this is only the progress bookkeeping.
func (r *runner) reap(ctx context.Context) {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			r.mu.Lock()
			for id, j := range r.jobs {
				if _, done := j.snapshot(); done && time.Since(j.finishedAt) > 30*time.Minute {
					delete(r.jobs, id)
				}
			}
			r.mu.Unlock()
		}
	}
}

func (r *runner) submit(req jobRequest) (*job, error) {
	j := &job{id: newID(), req: req, subs: map[chan event]struct{}{}}
	j.last = event{Stage: "queued", Label: "waiting for a slot"}

	r.mu.Lock()
	r.jobs[j.id] = j
	r.mu.Unlock()

	select {
	case r.queue <- j:
		return j, nil
	default:
		r.mu.Lock()
		delete(r.jobs, j.id)
		r.mu.Unlock()
		return nil, errors.New("too many downloads queued, try again in a minute")
	}
}

func (r *runner) job(id string) (*job, bool) {
	r.mu.Lock()
	defer r.mu.Unlock()
	j, ok := r.jobs[id]
	return j, ok
}

func (r *runner) run(ctx context.Context, j *job) {
	dir := filepath.Join(r.cfg.cacheDir, j.id)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		j.publish(event{Stage: "error", Message: "could not make a working directory", terminal: true})
		return
	}

	j.publish(event{Stage: "prepare", Label: "asking the site about the video"})

	meta, err := probe(ctx, r.cfg, j.req.URL)
	if err != nil {
		os.RemoveAll(dir)
		j.publish(event{Stage: "error", Message: err.Error(), terminal: true})
		return
	}

	j.publish(event{Stage: "download", Label: "downloading"})

	if err := r.fetch(ctx, j, dir); err != nil {
		os.RemoveAll(dir)
		j.publish(event{Stage: "error", Message: err.Error(), terminal: true})
		return
	}

	e, err := r.finish(j, dir, meta)
	if err != nil {
		os.RemoveAll(dir)
		j.publish(event{Stage: "error", Message: err.Error(), terminal: true})
		return
	}

	r.store.enforceLimit(e.ID)

	ready := e.public()
	j.publish(event{Stage: "done", Label: "ready", Percent: 100, Entry: &ready, terminal: true})
}

// fetch runs yt-dlp and turns its progress lines into events
func (r *runner) fetch(ctx context.Context, j *job, dir string) error {
	args := buildArgs(r.cfg, j.req, dir)
	cmd := command(ctx, r.cfg.ytdlp, args...)

	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}
	stderr, err := cmd.StderrPipe()
	if err != nil {
		return err
	}

	log.Printf("job %s: yt-dlp %s", j.id, strings.Join(args, " "))
	if err := cmd.Start(); err != nil {
		return errors.New("could not start yt-dlp")
	}

	var errTail strings.Builder
	var wg sync.WaitGroup
	wg.Add(2)

	go func() {
		defer wg.Done()
		scan := bufio.NewScanner(stdout)
		scan.Buffer(make([]byte, 0, 64*1024), 1024*1024)
		for scan.Scan() {
			if ev, ok := parseLine(scan.Text()); ok {
				j.publish(ev)
			}
		}
	}()

	go func() {
		defer wg.Done()
		io.Copy(tailWriter{&errTail}, stderr)
	}()

	wg.Wait()
	if err := cmd.Wait(); err != nil {
		if ctx.Err() != nil {
			return errors.New("the server was restarting, nothing was saved")
		}
		if msg := strings.TrimSpace(errTail.String()); msg != "" {
			return errors.New(ytdlpError(msg))
		}
		return errors.New("yt-dlp gave up on that link")
	}
	return nil
}

// finish moves the result where the request asked for and records it
func (r *runner) finish(j *job, dir string, meta probeResult) (*entry, error) {
	media, err := findMedia(dir)
	if err != nil {
		return nil, err
	}
	sweepSidecars(dir, media)

	info, err := os.Stat(media)
	if err != nil {
		return nil, errors.New("the finished file vanished")
	}

	e := &entry{
		ID:        j.id,
		Title:     meta.Title,
		Uploader:  meta.author(),
		URL:       j.req.URL,
		Thumbnail: meta.Thumbnail,
		Duration:  meta.Duration,
		Format:    j.req.Format,
		Quality:   qualityLabel(j.req),
		Name:      filepath.Base(media),
		Size:      info.Size(),
		Created:   time.Now(),
		CachePath: media,
	}

	if j.req.Mode == "library" || j.req.Mode == "both" {
		dst := r.cfg.videoDir
		if j.req.Format == "mp3" {
			dst = r.cfg.audioDir
		}
		keepCache := j.req.Mode == "both"

		archived, err := place(media, dst, e.Name, keepCache)
		if err != nil {
			return nil, fmt.Errorf("could not file it into the library: %w", err)
		}
		e.ArchivePath = archived
		if !keepCache {
			e.CachePath = ""
		}
	}

	if err := r.store.add(e); err != nil {
		return nil, errors.New("could not record the download")
	}
	return e, nil
}

func buildArgs(cfg config, req jobRequest, dir string) []string {
	args := []string{
		"--no-playlist",
		"--no-part",
		"--no-color",
		"--no-warnings",
		"--newline",
		"--progress",
		"--progress-template",
		"PROGRESS|%(progress.status)s|%(progress.downloaded_bytes)s|%(progress.total_bytes)s|%(progress.total_bytes_estimate)s|%(progress.speed)s|%(progress.eta)s",
		"--ffmpeg-location", cfg.ffmpeg,
		"--retries", "5",
		"--fragment-retries", "10",
		"--concurrent-fragments", "4",
		"--socket-timeout", "20",
		"-P", dir,
		"-o", "%(title).150B [%(id)s].%(ext)s",
	}
	args = append(args, cookieArgs(cfg)...)

	if cfg.maxFileSize != "" && cfg.maxFileSize != "0" {
		args = append(args, "--max-filesize", cfg.maxFileSize)
	}

	if req.Format == "mp3" {
		args = append(args,
			"-f", "ba/b",
			"-x", "--audio-format", "mp3",
			"--audio-quality", fmt.Sprintf("%dK", req.Bitrate),
		)
		// cutting audio is cheap, so on the audio side sponsor segments really go away
		if req.SponsorBlock {
			args = append(args, "--sponsorblock-remove", "sponsor,selfpromo,interaction,music_offtopic")
		}
	} else {
		selector := "bv*[ext=mp4]+ba[ext=m4a]/bv*+ba/b"
		if req.Height > 0 {
			selector = fmt.Sprintf(
				"bv*[height<=%[1]d][ext=mp4]+ba[ext=m4a]/bv*[height<=%[1]d]+ba/b[height<=%[1]d]/bv*+ba/b",
				req.Height,
			)
		}
		args = append(args, "-f", selector, "--merge-output-format", "mp4", "--remux-video", "mp4")
		// removing segments from video means a full re-encode, which on a pi 4 is
		// slower than the download by an order of magnitude, so only mark them
		if req.SponsorBlock {
			args = append(args, "--sponsorblock-mark", "all")
		}
	}

	if req.Metadata {
		args = append(args, "--embed-metadata", "--embed-chapters")
	}
	if req.Thumbnail {
		args = append(args, "--embed-thumbnail")
	}

	return append(args, "--", req.URL)
}

var stages = []struct {
	prefix string
	label  string
}{
	{"[download] Destination:", "downloading"},
	{"[Merger]", "merging video and audio"},
	{"[VideoRemuxer]", "remuxing to mp4"},
	{"[ExtractAudio]", "extracting audio"},
	{"[SponsorBlock]", "checking sponsorblock"},
	{"[ModifyChapters]", "cutting sponsor segments"},
	{"[Metadata]", "writing metadata"},
	{"[ThumbnailsConvertor]", "converting cover art"},
	{"[EmbedThumbnail]", "embedding cover art"},
	{"[FixupM3u8]", "fixing the container"},
	{"[FixupM4a]", "fixing the container"},
	{"[Fixup", "fixing the container"},
}

func parseLine(line string) (event, bool) {
	if rest, ok := strings.CutPrefix(line, "PROGRESS|"); ok {
		return parseProgress(rest)
	}
	for _, s := range stages {
		if strings.HasPrefix(line, s.prefix) {
			stage := "process"
			if s.prefix == "[download] Destination:" {
				stage = "download"
			}
			return event{Stage: stage, Label: s.label}, true
		}
	}
	return event{}, false
}

func parseProgress(rest string) (event, bool) {
	fields := strings.Split(rest, "|")
	if len(fields) < 6 {
		return event{}, false
	}

	status := fields[0]
	done := number(fields[1])
	total := number(fields[2])
	if total <= 0 {
		total = number(fields[3])
	}

	ev := event{Stage: "download", Label: "downloading", Speed: positive(fields[4]), ETA: positive(fields[5])}
	if total > 0 {
		ev.Total = int64(total)
		ev.Percent = done / total * 100
		if ev.Percent > 100 {
			ev.Percent = 100
		}
	}
	if status == "finished" {
		ev.Percent = 100
		ev.Speed, ev.ETA = 0, 0
		ev.Label = "downloaded"
	}
	return ev, true
}

// yt-dlp renders unknown template values as NA rather than leaving them out
func number(field string) float64 {
	v, err := strconv.ParseFloat(strings.TrimSpace(field), 64)
	if err != nil {
		return -1
	}
	return v
}

// positive keeps unknown values out of the json entirely, so the ui does not
// have to know that -1 means "yt-dlp has no idea yet"
func positive(field string) float64 {
	if v := number(field); v > 0 {
		return v
	}
	return 0
}

func qualityLabel(req jobRequest) string {
	if req.Format == "mp3" {
		return fmt.Sprintf("%d kbps", req.Bitrate)
	}
	if req.Height > 0 {
		return fmt.Sprintf("%dp", req.Height)
	}
	return "best"
}

var sidecarExts = map[string]bool{
	".part": true, ".ytdl": true, ".json": true, ".webp": true, ".jpg": true,
	".jpeg": true, ".png": true, ".vtt": true, ".srt": true, ".lrc": true,
	".tmp": true, ".description": true, ".temp": true,
}

func findMedia(dir string) (string, error) {
	items, err := os.ReadDir(dir)
	if err != nil {
		return "", err
	}

	var best string
	var bestSize int64
	for _, item := range items {
		if item.IsDir() || item.Name() == "meta.json" {
			continue
		}
		if sidecarExts[strings.ToLower(filepath.Ext(item.Name()))] {
			continue
		}
		info, err := item.Info()
		if err != nil {
			continue
		}
		if info.Size() > bestSize {
			best, bestSize = filepath.Join(dir, item.Name()), info.Size()
		}
	}

	if best == "" {
		return "", errors.New("yt-dlp finished but left no file behind")
	}
	return best, nil
}

// sweepSidecars keeps the cache size honest: leftover thumbnails and json are
// not counted against the cap, so they must not stay on disk either
func sweepSidecars(dir, keep string) {
	items, err := os.ReadDir(dir)
	if err != nil {
		return
	}
	for _, item := range items {
		path := filepath.Join(dir, item.Name())
		if item.IsDir() || path == keep || item.Name() == "meta.json" {
			continue
		}
		os.Remove(path)
	}
}

func newID() string {
	buf := make([]byte, 6)
	rand.Read(buf)
	return hex.EncodeToString(buf)
}

func validID(id string) bool {
	if len(id) != 12 {
		return false
	}
	_, err := hex.DecodeString(id)
	return err == nil
}

// tailWriter keeps only the last few KB of yt-dlp's stderr, which is all the
// error reporting ever needs
type tailWriter struct{ buf *strings.Builder }

func (w tailWriter) Write(p []byte) (int, error) {
	w.buf.Write(p)
	if w.buf.Len() > 8192 {
		s := w.buf.String()
		w.buf.Reset()
		w.buf.WriteString(s[len(s)-4096:])
	}
	return len(p), nil
}
