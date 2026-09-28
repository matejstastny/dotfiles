package main

import (
	"os"
	"strconv"
	"strings"
)

type config struct {
	listen      string
	dir         string
	maxFiles    int
	maxFileSize int64
}

func loadConfig() config {
	c := config{
		listen: env("SHARE_LISTEN", "127.0.0.1:8091"),
		dir:    env("SHARE_DIR", "/var/lib/share/files"),
	}

	maxFiles, err := strconv.Atoi(env("SHARE_MAX_FILES", "10"))
	if err != nil || maxFiles < 1 {
		maxFiles = 10
	}
	c.maxFiles = maxFiles

	limitGB, err := strconv.ParseFloat(env("SHARE_MAX_FILESIZE_GB", "5"), 64)
	if err != nil || limitGB <= 0 {
		limitGB = 5
	}
	c.maxFileSize = int64(limitGB * 1e9)

	return c
}

func env(key, fallback string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return fallback
}
