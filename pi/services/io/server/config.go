package main

import (
	"os"
	"strconv"
	"strings"
)

type config struct {
	listen      string
	cacheDir    string
	videoDir    string
	audioDir    string
	cacheLimit  int64
	maxFileSize string
	ytdlp       string
	ffmpeg      string
	cookies     string
	workers     int
}

func loadConfig() config {
	c := config{
		listen:      env("YTDL_LISTEN", "127.0.0.1:8090"),
		cacheDir:    env("YTDL_CACHE_DIR", "/var/lib/ytdl/cache"),
		videoDir:    env("YTDL_VIDEO_DIR", "/srv/media/video"),
		audioDir:    env("YTDL_AUDIO_DIR", "/srv/media/music"),
		maxFileSize: env("YTDL_MAX_FILESIZE", "10G"),
		ytdlp:       env("YTDL_YTDLP", "/usr/bin/yt-dlp"),
		ffmpeg:      env("YTDL_FFMPEG", "/usr/bin/ffmpeg"),
		cookies:     env("YTDL_COOKIES", "/var/lib/ytdl/cookies.txt"),
	}

	limit, err := strconv.ParseFloat(env("YTDL_CACHE_LIMIT_GB", "20"), 64)
	if err != nil || limit <= 0 {
		limit = 20
	}
	c.cacheLimit = int64(limit * 1e9)

	workers, err := strconv.Atoi(env("YTDL_WORKERS", "2"))
	if err != nil || workers < 1 {
		workers = 2
	}
	c.workers = workers

	return c
}

func env(key, fallback string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return fallback
}

// cookieArgs is skipped whenever the file is absent, which is the default and
// keeps ordinary videos working with nothing extra to configure. YouTube's age
// and bot gates are the reason it exists at all: yt-dlp needs a real logged-in
// session to get past them, and a headless box has no browser to pull one from.
func cookieArgs(cfg config) []string {
	if cfg.cookies == "" {
		return nil
	}
	if _, err := os.Stat(cfg.cookies); err != nil {
		return nil
	}
	return []string{"--cookies", cfg.cookies}
}
