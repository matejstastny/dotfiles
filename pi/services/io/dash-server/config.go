package main

import (
	"os"
	"strings"
	"time"
)

type config struct {
	listen  string
	vmURL   string
	catalog string

	lookback time.Duration
	step     time.Duration

	metricsEvery time.Duration
	probeEvery   time.Duration
	serviceEvery time.Duration

	probeTimeout time.Duration

	adguardURL  string
	adguardUser string
	adguardPass string

	transmissionURL string
	jellyfinURL     string
	ytdlURL         string
	shareURL        string

	tailscaleBin string
}

func loadConfig() config {
	c := config{
		listen:  env("DASH_LISTEN", "127.0.0.1:8092"),
		vmURL:   env("DASH_VM_URL", "http://127.0.0.1:8428"),
		catalog: env("DASH_CATALOG", "/etc/dash/catalog.json"),

		adguardURL:  env("DASH_ADGUARD_URL", ""),
		adguardUser: env("DASH_ADGUARD_USER", ""),
		adguardPass: env("DASH_ADGUARD_PASS", ""),

		transmissionURL: env("DASH_TRANSMISSION_URL", "http://127.0.0.1:9091/transmission/rpc"),
		jellyfinURL:     env("DASH_JELLYFIN_URL", "http://127.0.0.1:8096"),
		ytdlURL:         env("DASH_YTDL_URL", "http://127.0.0.1:8090"),
		shareURL:        env("DASH_SHARE_URL", "http://127.0.0.1:8091"),

		tailscaleBin: env("DASH_TAILSCALE_BIN", "/usr/bin/tailscale"),
	}

	c.lookback = parseDuration(env("DASH_LOOKBACK", "3h"), 3*time.Hour)
	c.step = parseDuration(env("DASH_STEP", "2m"), 2*time.Minute)

	// node-exporter is scraped every 15s, so refreshing the metric cache any
	// faster than that only re-reads the same points
	c.metricsEvery = parseDuration(env("DASH_METRICS_EVERY", "15s"), 15*time.Second)
	c.probeEvery = parseDuration(env("DASH_PROBE_EVERY", "20s"), 20*time.Second)
	c.serviceEvery = parseDuration(env("DASH_SERVICE_EVERY", "20s"), 20*time.Second)
	c.probeTimeout = parseDuration(env("DASH_PROBE_TIMEOUT", "2s"), 2*time.Second)

	return c
}

func env(key, fallback string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return fallback
}

func parseDuration(v string, fallback time.Duration) time.Duration {
	d, err := time.ParseDuration(v)
	if err != nil || d <= 0 {
		return fallback
	}
	return d
}
