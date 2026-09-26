package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os/exec"
	"sort"
	"strings"
	"sync"
	"time"
)

type probeResult struct {
	Type       string  `json:"_type"`
	ID         string  `json:"id"`
	Title      string  `json:"title"`
	Uploader   string  `json:"uploader"`
	Channel    string  `json:"channel"`
	Duration   float64 `json:"duration"`
	Thumbnail  string  `json:"thumbnail"`
	WebpageURL string  `json:"webpage_url"`
	Extractor  string  `json:"extractor_key"`
	IsLive     bool    `json:"is_live"`
	LiveStatus string  `json:"live_status"`
	Formats    []struct {
		Height int    `json:"height"`
		VCodec string `json:"vcodec"`
	} `json:"formats"`
}

func (p probeResult) author() string {
	if p.Uploader != "" {
		return p.Uploader
	}
	return p.Channel
}

// heights lists the video resolutions actually on offer, tallest first, so the
// picker never shows a 4K option for a 480p video
func (p probeResult) heights() []int {
	seen := map[int]bool{}
	for _, f := range p.Formats {
		if f.Height > 0 && f.VCodec != "" && f.VCodec != "none" {
			seen[f.Height] = true
		}
	}
	out := make([]int, 0, len(seen))
	for h := range seen {
		out = append(out, h)
	}
	sort.Sort(sort.Reverse(sort.IntSlice(out)))
	return out
}

func probe(ctx context.Context, cfg config, url string) (probeResult, error) {
	ctx, cancel := context.WithTimeout(ctx, 60*time.Second)
	defer cancel()

	args := append([]string{
		"-J", "--no-playlist", "--no-warnings", "--no-progress",
		"--socket-timeout", "15",
	}, cookieArgs(cfg)...)
	args = append(args, "--", url)

	cmd := exec.CommandContext(ctx, cfg.ytdlp, args...)
	var stdout, stderr strings.Builder
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		if ctx.Err() != nil {
			return probeResult{}, errors.New("timed out asking the site about that link")
		}
		return probeResult{}, errors.New(ytdlpError(stderr.String()))
	}

	var result probeResult
	if err := json.Unmarshal([]byte(stdout.String()), &result); err != nil {
		return probeResult{}, errors.New("could not read what yt-dlp said about that link")
	}

	if result.Type == "playlist" {
		return probeResult{}, errors.New("that is a playlist or a channel, paste a single video link")
	}
	if result.IsLive || result.LiveStatus == "is_live" {
		return probeResult{}, errors.New("that is a live stream, wait until it ends")
	}
	if result.Title == "" {
		return probeResult{}, errors.New("nothing downloadable behind that link")
	}
	return result, nil
}

// ytdlpError turns a wall of yt-dlp stderr into the one line worth reading
func ytdlpError(stderr string) string {
	lines := strings.Split(strings.TrimSpace(stderr), "\n")
	for i := len(lines) - 1; i >= 0; i-- {
		line := strings.TrimSpace(lines[i])
		if strings.HasPrefix(line, "ERROR:") {
			msg := strings.TrimSpace(strings.TrimPrefix(line, "ERROR:"))
			if idx := strings.Index(msg, ";"); idx > 0 {
				msg = msg[:idx]
			}
			return msg
		}
	}
	if len(lines) > 0 && lines[len(lines)-1] != "" {
		return lines[len(lines)-1]
	}
	return "yt-dlp failed without saying why"
}

// probeCache exists because submitting a job re-probes to get the title and
// thumbnail server side, and paying for that twice in a row is silly
type probeCache struct {
	mu      sync.Mutex
	entries map[string]probeEntry
	ttl     time.Duration
}

type probeEntry struct {
	result probeResult
	at     time.Time
}

func newProbeCache() *probeCache {
	return &probeCache{entries: map[string]probeEntry{}, ttl: 10 * time.Minute}
}

func (c *probeCache) get(ctx context.Context, cfg config, url string) (probeResult, error) {
	c.mu.Lock()
	hit, ok := c.entries[url]
	c.mu.Unlock()
	if ok && time.Since(hit.at) < c.ttl {
		return hit.result, nil
	}

	result, err := probe(ctx, cfg, url)
	if err != nil {
		return probeResult{}, err
	}

	c.mu.Lock()
	if len(c.entries) > 64 {
		c.entries = map[string]probeEntry{}
	}
	c.entries[url] = probeEntry{result: result, at: time.Now()}
	c.mu.Unlock()

	return result, nil
}

func durationLabel(seconds float64) string {
	total := int(seconds)
	if total <= 0 {
		return ""
	}
	h, m, s := total/3600, (total/60)%60, total%60
	if h > 0 {
		return fmt.Sprintf("%d:%02d:%02d", h, m, s)
	}
	return fmt.Sprintf("%d:%02d", m, s)
}
