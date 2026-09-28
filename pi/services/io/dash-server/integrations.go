package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"sort"
	"strings"
	"sync"
	"time"
)

type integrations struct {
	AdGuard      *adguardInfo      `json:"adguard"`
	Transmission *transmissionInfo `json:"transmission"`
	Jellyfin     *jellyfinInfo     `json:"jellyfin"`
	Ytdl         *ytdlInfo         `json:"ytdl"`
	Share        *shareInfo        `json:"share"`
	Victoria     *victoriaInfo     `json:"victoria"`
}

type nameCount struct {
	Name  string  `json:"name"`
	Count float64 `json:"count"`
}

type collector struct {
	cfg  config
	http *http.Client

	// transmission hands out a session id and then rejects every request that
	// does not carry it, so it is kept between refreshes and only re-fetched
	// when the daemon says it went stale
	mu        sync.Mutex
	txSession string
}

func newCollector(cfg config) *collector {
	return &collector{
		cfg:  cfg,
		http: &http.Client{Timeout: 8 * time.Second},
	}
}

func (c *collector) collect(ctx context.Context) integrations {
	var (
		out integrations
		mu  sync.Mutex
		wg  sync.WaitGroup
	)

	run := func(name string, fn func() error) {
		wg.Add(1)
		go func() {
			defer wg.Done()
			if err := fn(); err != nil {
				logOnce(name, err)
			}
		}()
	}

	run("adguard", func() error {
		v, err := c.adguard(ctx)
		if err != nil {
			return err
		}
		mu.Lock()
		out.AdGuard = v
		mu.Unlock()
		return nil
	})
	run("transmission", func() error {
		v, err := c.transmission(ctx)
		if err != nil {
			return err
		}
		mu.Lock()
		out.Transmission = v
		mu.Unlock()
		return nil
	})
	run("jellyfin", func() error {
		v, err := c.jellyfin(ctx)
		if err != nil {
			return err
		}
		mu.Lock()
		out.Jellyfin = v
		mu.Unlock()
		return nil
	})
	run("ytdl", func() error {
		v, err := c.ytdl(ctx)
		if err != nil {
			return err
		}
		mu.Lock()
		out.Ytdl = v
		mu.Unlock()
		return nil
	})
	run("share", func() error {
		v, err := c.share(ctx)
		if err != nil {
			return err
		}
		mu.Lock()
		out.Share = v
		mu.Unlock()
		return nil
	})
	run("victoria", func() error {
		v, err := c.victoria(ctx)
		if err != nil {
			return err
		}
		mu.Lock()
		out.Victoria = v
		mu.Unlock()
		return nil
	})

	wg.Wait()
	return out
}

func (c *collector) getJSON(ctx context.Context, url string, basicUser, basicPass string, into any) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return err
	}
	if basicUser != "" {
		req.SetBasicAuth(basicUser, basicPass)
	}
	res, err := c.http.Do(req)
	if err != nil {
		return err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("%s answered %s", url, res.Status)
	}
	return json.NewDecoder(res.Body).Decode(into)
}

/* ---------- adguard home ---------- */

type adguardInfo struct {
	Version     string      `json:"version"`
	Protection  bool        `json:"protection"`
	Running     bool        `json:"running"`
	UptimeSec   float64     `json:"uptimeSec"`
	Queries     float64     `json:"queries"`
	Blocked     float64     `json:"blocked"`
	BlockedPct  float64     `json:"blockedPct"`
	Safebrowse  float64     `json:"safebrowsing"`
	AvgMs       float64     `json:"avgMs"`
	Upstream    string      `json:"upstream"`
	UpstreamMs  float64     `json:"upstreamMs"`
	Addresses   []string    `json:"addresses"`
	PerHour     []float64   `json:"perHour"`
	BlockedHour []float64   `json:"blockedHour"`
	TopQueried  []nameCount `json:"topQueried"`
	TopBlocked  []nameCount `json:"topBlocked"`
	TopClients  []nameCount `json:"topClients"`
}

func (c *collector) adguard(ctx context.Context) (*adguardInfo, error) {
	if c.cfg.adguardURL == "" {
		return nil, nil
	}

	var status struct {
		Version      string   `json:"version"`
		Protection   bool     `json:"protection_enabled"`
		Running      bool     `json:"running"`
		DNSAddresses []string `json:"dns_addresses"`
		StartTime    float64  `json:"start_time"`
	}
	if err := c.getJSON(ctx, c.cfg.adguardURL+"/control/status", c.cfg.adguardUser, c.cfg.adguardPass, &status); err != nil {
		return nil, err
	}

	var stats struct {
		Queries    float64              `json:"num_dns_queries"`
		Blocked    float64              `json:"num_blocked_filtering"`
		Safebrowse float64              `json:"num_replaced_safebrowsing"`
		AvgTime    float64              `json:"avg_processing_time"`
		PerHour    []float64            `json:"dns_queries"`
		BlockHour  []float64            `json:"blocked_filtering"`
		TopQueried []map[string]float64 `json:"top_queried_domains"`
		TopBlocked []map[string]float64 `json:"top_blocked_domains"`
		TopClients []map[string]float64 `json:"top_clients"`
		Upstreams  []map[string]float64 `json:"top_upstreams_responses"`
		UpstreamMs []map[string]float64 `json:"top_upstreams_avg_time"`
	}
	if err := c.getJSON(ctx, c.cfg.adguardURL+"/control/stats", c.cfg.adguardUser, c.cfg.adguardPass, &stats); err != nil {
		return nil, err
	}

	info := &adguardInfo{
		Version:     status.Version,
		Protection:  status.Protection,
		Running:     status.Running,
		Queries:     stats.Queries,
		Blocked:     stats.Blocked,
		Safebrowse:  stats.Safebrowse,
		AvgMs:       stats.AvgTime * 1000,
		PerHour:     stats.PerHour,
		BlockedHour: stats.BlockHour,
		TopQueried:  flattenCounts(stats.TopQueried, 8),
		TopBlocked:  flattenCounts(stats.TopBlocked, 8),
		TopClients:  flattenCounts(stats.TopClients, 8),
	}
	if stats.Queries > 0 {
		info.BlockedPct = stats.Blocked / stats.Queries * 100
	}
	// start_time is milliseconds since the epoch
	if status.StartTime > 0 {
		info.UptimeSec = time.Since(time.UnixMilli(int64(status.StartTime))).Seconds()
	}
	if up := flattenCounts(stats.Upstreams, 1); len(up) > 0 {
		info.Upstream = up[0].Name
	}
	if up := flattenCounts(stats.UpstreamMs, 1); len(up) > 0 {
		info.UpstreamMs = up[0].Count * 1000
	}
	// only the routable ones are worth showing; the link locals are noise
	for _, addr := range status.DNSAddresses {
		if !strings.HasPrefix(addr, "fe80::") && addr != "::1" && addr != "127.0.0.1" {
			info.Addresses = append(info.Addresses, addr)
		}
	}
	return info, nil
}

// adguard returns its top-N lists as a list of one-key objects rather than a
// list of pairs, so they have to be unwrapped and re-sorted
func flattenCounts(in []map[string]float64, limit int) []nameCount {
	out := make([]nameCount, 0, len(in))
	for _, entry := range in {
		for name, count := range entry {
			out = append(out, nameCount{Name: name, Count: count})
		}
	}
	sort.SliceStable(out, func(i, j int) bool { return out[i].Count > out[j].Count })
	if len(out) > limit {
		out = out[:limit]
	}
	return out
}

/* ---------- transmission ---------- */

type transmissionInfo struct {
	Torrents  int       `json:"torrents"`
	Active    int       `json:"active"`
	Paused    int       `json:"paused"`
	DownBps   float64   `json:"downBps"`
	UpBps     float64   `json:"upBps"`
	DownTotal float64   `json:"downTotal"`
	UpTotal   float64   `json:"upTotal"`
	Ratio     float64   `json:"ratio"`
	ActiveSec float64   `json:"activeSec"`
	List      []torrent `json:"list"`
}

type torrent struct {
	Name    string  `json:"name"`
	Status  string  `json:"status"`
	Percent float64 `json:"percent"`
	Size    float64 `json:"size"`
	DownBps float64 `json:"downBps"`
	UpBps   float64 `json:"upBps"`
	Ratio   float64 `json:"ratio"`
	Peers   int     `json:"peers"`
	ETASec  float64 `json:"etaSec"`
}

// transmission's numeric status codes, in rpc-spec order
var torrentStatus = map[int]string{
	0: "paused", 1: "check wait", 2: "checking",
	3: "queued", 4: "downloading", 5: "seed wait", 6: "seeding",
}

func (c *collector) transmission(ctx context.Context) (*transmissionInfo, error) {
	var stats struct {
		Arguments struct {
			TorrentCount   int     `json:"torrentCount"`
			ActiveCount    int     `json:"activeTorrentCount"`
			PausedCount    int     `json:"pausedTorrentCount"`
			DownloadSpeed  float64 `json:"downloadSpeed"`
			UploadSpeed    float64 `json:"uploadSpeed"`
			CumulativeStat struct {
				Downloaded    float64 `json:"downloadedBytes"`
				Uploaded      float64 `json:"uploadedBytes"`
				SecondsActive float64 `json:"secondsActive"`
			} `json:"cumulative-stats"`
		} `json:"arguments"`
	}
	if err := c.rpc(ctx, `{"method":"session-stats"}`, &stats); err != nil {
		return nil, err
	}

	var list struct {
		Arguments struct {
			Torrents []struct {
				Name    string  `json:"name"`
				Status  int     `json:"status"`
				Percent float64 `json:"percentDone"`
				Size    float64 `json:"totalSize"`
				Down    float64 `json:"rateDownload"`
				Up      float64 `json:"rateUpload"`
				Ratio   float64 `json:"uploadRatio"`
				Peers   int     `json:"peersConnected"`
				ETA     float64 `json:"eta"`
			} `json:"torrents"`
		} `json:"arguments"`
	}
	const fields = `["name","status","percentDone","rateDownload","rateUpload","eta","totalSize","uploadRatio","peersConnected"]`
	if err := c.rpc(ctx, `{"method":"torrent-get","arguments":{"fields":`+fields+`}}`, &list); err != nil {
		return nil, err
	}

	a := stats.Arguments
	info := &transmissionInfo{
		Torrents:  a.TorrentCount,
		Active:    a.ActiveCount,
		Paused:    a.PausedCount,
		DownBps:   a.DownloadSpeed,
		UpBps:     a.UploadSpeed,
		DownTotal: a.CumulativeStat.Downloaded,
		UpTotal:   a.CumulativeStat.Uploaded,
		ActiveSec: a.CumulativeStat.SecondsActive,
	}
	if a.CumulativeStat.Downloaded > 0 {
		info.Ratio = a.CumulativeStat.Uploaded / a.CumulativeStat.Downloaded
	}

	for _, t := range list.Arguments.Torrents {
		status, ok := torrentStatus[t.Status]
		if !ok {
			status = "unknown"
		}
		info.List = append(info.List, torrent{
			Name: t.Name, Status: status, Percent: t.Percent * 100, Size: t.Size,
			DownBps: t.Down, UpBps: t.Up, Ratio: t.Ratio, Peers: t.Peers, ETASec: t.ETA,
		})
	}
	// busiest first, so a download in progress is always the top row
	sort.SliceStable(info.List, func(i, j int) bool {
		return info.List[i].DownBps+info.List[i].UpBps > info.List[j].DownBps+info.List[j].UpBps
	})
	if len(info.List) > 8 {
		info.List = info.List[:8]
	}
	return info, nil
}

func (c *collector) rpc(ctx context.Context, body string, into any) error {
	send := func(session string) (*http.Response, error) {
		req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.cfg.transmissionURL, bytes.NewBufferString(body))
		if err != nil {
			return nil, err
		}
		req.Header.Set("Content-Type", "application/json")
		if session != "" {
			req.Header.Set("X-Transmission-Session-Id", session)
		}
		return c.http.Do(req)
	}

	c.mu.Lock()
	session := c.txSession
	c.mu.Unlock()

	res, err := send(session)
	if err != nil {
		return err
	}
	// 409 means the session id rotated; take the fresh one from the response
	// and replay once
	if res.StatusCode == http.StatusConflict {
		session = res.Header.Get("X-Transmission-Session-Id")
		res.Body.Close()
		c.mu.Lock()
		c.txSession = session
		c.mu.Unlock()
		if res, err = send(session); err != nil {
			return err
		}
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("transmission answered %s", res.Status)
	}
	return json.NewDecoder(res.Body).Decode(into)
}

/* ---------- jellyfin ---------- */

type jellyfinInfo struct {
	Name    string `json:"name"`
	Version string `json:"version"`
	Product string `json:"product"`
	SetupOK bool   `json:"setupOk"`
}

func (c *collector) jellyfin(ctx context.Context) (*jellyfinInfo, error) {
	var out struct {
		ServerName  string `json:"ServerName"`
		Version     string `json:"Version"`
		ProductName string `json:"ProductName"`
		Startup     bool   `json:"StartupWizardCompleted"`
	}
	if err := c.getJSON(ctx, c.cfg.jellyfinURL+"/System/Info/Public", "", "", &out); err != nil {
		return nil, err
	}
	return &jellyfinInfo{Name: out.ServerName, Version: out.Version, Product: out.ProductName, SetupOK: out.Startup}, nil
}

/* ---------- ytdl ---------- */

type ytdlInfo struct {
	CacheUsed  float64    `json:"cacheUsed"`
	CacheLimit float64    `json:"cacheLimit"`
	CachePct   float64    `json:"cachePct"`
	Count      int        `json:"count"`
	Recent     []ytdlFile `json:"recent"`
}

type ytdlFile struct {
	Title    string  `json:"title"`
	Uploader string  `json:"uploader"`
	Format   string  `json:"format"`
	Quality  string  `json:"quality"`
	Size     float64 `json:"size"`
	Duration float64 `json:"duration"`
	Created  string  `json:"created"`
	Library  bool    `json:"library"`
}

func (c *collector) ytdl(ctx context.Context) (*ytdlInfo, error) {
	var out struct {
		Cache struct {
			Limit float64 `json:"limit"`
			Used  float64 `json:"used"`
		} `json:"cache"`
		Files []ytdlFile `json:"files"`
	}
	if err := c.getJSON(ctx, c.cfg.ytdlURL+"/api/files", "", "", &out); err != nil {
		return nil, err
	}
	info := &ytdlInfo{CacheUsed: out.Cache.Used, CacheLimit: out.Cache.Limit, Count: len(out.Files)}
	if out.Cache.Limit > 0 {
		info.CachePct = out.Cache.Used / out.Cache.Limit * 100
	}
	info.Recent = out.Files
	if len(info.Recent) > 5 {
		info.Recent = info.Recent[:5]
	}
	return info, nil
}

/* ---------- share ---------- */

type shareInfo struct {
	Count  int         `json:"count"`
	Limit  int         `json:"limit"`
	Bytes  float64     `json:"bytes"`
	Recent []shareFile `json:"recent"`
}

type shareFile struct {
	Name    string  `json:"name"`
	Size    float64 `json:"size"`
	Created string  `json:"created"`
}

func (c *collector) share(ctx context.Context) (*shareInfo, error) {
	var out struct {
		Files []shareFile `json:"files"`
		Limit int         `json:"limit"`
	}
	if err := c.getJSON(ctx, c.cfg.shareURL+"/api/files", "", "", &out); err != nil {
		return nil, err
	}
	info := &shareInfo{Count: len(out.Files), Limit: out.Limit}
	for _, f := range out.Files {
		info.Bytes += f.Size
	}
	info.Recent = out.Files
	if len(info.Recent) > 5 {
		info.Recent = info.Recent[:5]
	}
	return info, nil
}

/* ---------- victoria metrics ---------- */

type victoriaInfo struct {
	Series     float64 `json:"series"`
	LabelPairs float64 `json:"labelPairs"`
	Rows       float64 `json:"rows"`
	DataBytes  float64 `json:"dataBytes"`
	FreeBytes  float64 `json:"freeBytes"`
	UptimeSec  float64 `json:"uptimeSec"`
	Version    string  `json:"version"`
	Retention  string  `json:"retention"`
}

func (c *collector) victoria(ctx context.Context) (*victoriaInfo, error) {
	var tsdb struct {
		Data struct {
			TotalSeries          float64 `json:"totalSeries"`
			TotalLabelValuePairs float64 `json:"totalLabelValuePairs"`
		} `json:"data"`
	}
	if err := c.getJSON(ctx, c.cfg.vmURL+"/api/v1/status/tsdb", "", "", &tsdb); err != nil {
		return nil, err
	}

	info := &victoriaInfo{
		Series:     tsdb.Data.TotalSeries,
		LabelPairs: tsdb.Data.TotalLabelValuePairs,
		Retention:  env("DASH_VM_RETENTION", "90d"),
	}

	// victoria-metrics exposes its own internals only as prometheus text, so
	// these few gauges get picked out by hand rather than pulling in a parser
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.cfg.vmURL+"/metrics", nil)
	if err != nil {
		return info, nil
	}
	res, err := c.http.Do(req)
	if err != nil {
		return info, nil
	}
	defer res.Body.Close()

	buf := new(bytes.Buffer)
	buf.ReadFrom(res.Body)
	for line := range strings.Lines(buf.String()) {
		name, value, ok := promLine(line)
		if !ok {
			continue
		}
		switch {
		case strings.HasPrefix(name, "vm_rows{type=\"storage/"):
			info.Rows += value
		case strings.HasPrefix(name, "vm_data_size_bytes{"):
			info.DataBytes += value
		case strings.HasPrefix(name, "vm_free_disk_space_bytes{"):
			info.FreeBytes = value
		case name == "vm_app_uptime_seconds":
			info.UptimeSec = value
		case strings.HasPrefix(name, "vm_app_version{"):
			if i := strings.Index(name, `version="`); i >= 0 {
				rest := name[i+len(`version="`):]
				if j := strings.Index(rest, `"`); j >= 0 {
					info.Version = rest[:j]
				}
			}
		}
	}
	return info, nil
}

// promLine splits one prometheus exposition line into its series (name plus
// labels) and its value, skipping comments
func promLine(line string) (string, float64, bool) {
	line = strings.TrimSpace(line)
	if line == "" || strings.HasPrefix(line, "#") {
		return "", 0, false
	}
	i := strings.LastIndex(line, " ")
	if i < 0 {
		return "", 0, false
	}
	var v float64
	if _, err := fmt.Sscanf(line[i+1:], "%g", &v); err != nil {
		return "", 0, false
	}
	return line[:i], v, true
}
