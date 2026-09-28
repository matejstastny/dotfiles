package main

import (
	"context"
	"sort"
	"time"
)

type hostStats struct {
	Name      string `json:"name"`
	Role      string `json:"role"`
	Blurb     string `json:"blurb"`
	Glyph     string `json:"glyph"`
	Accent    string `json:"accent"`
	AccentAlt string `json:"accentAlt"`
	LAN       string `json:"lan"`
	Tailnet   string `json:"tailnet"`
	Model     string `json:"model"`

	Online bool `json:"online"`

	Kernel    string  `json:"kernel"`
	Arch      string  `json:"arch"`
	UptimeSec float64 `json:"uptimeSec"`

	Cores     int       `json:"cores"`
	CPUPct    float64   `json:"cpuPct"`
	CorePct   []float64 `json:"corePct"`
	IOWaitPct float64   `json:"ioWaitPct"`
	FreqMHz   float64   `json:"freqMHz"`
	Governor  string    `json:"governor"`
	Load1     float64   `json:"load1"`
	Load5     float64   `json:"load5"`
	Load15    float64   `json:"load15"`

	MemUsed   float64 `json:"memUsed"`
	MemTotal  float64 `json:"memTotal"`
	MemPct    float64 `json:"memPct"`
	MemCached float64 `json:"memCached"`
	SwapUsed  float64 `json:"swapUsed"`
	SwapTotal float64 `json:"swapTotal"`

	Filesystems []filesystem `json:"filesystems"`
	DiskPct     float64      `json:"diskPct"`

	DiskReadBps  float64 `json:"diskReadBps"`
	DiskWriteBps float64 `json:"diskWriteBps"`

	NetDevice  string  `json:"netDevice"`
	NetRxBps   float64 `json:"netRxBps"`
	NetTxBps   float64 `json:"netTxBps"`
	NetRxTotal float64 `json:"netRxTotal"`
	NetTxTotal float64 `json:"netTxTotal"`
	NetErrs    float64 `json:"netErrs"`

	TempC float64 `json:"tempC"`

	ProcsRunning float64 `json:"procsRunning"`
	ProcsBlocked float64 `json:"procsBlocked"`
	CtxSwitches  float64 `json:"ctxSwitches"`
	Forks        float64 `json:"forks"`
	FdUsed       float64 `json:"fdUsed"`
	FdMax        float64 `json:"fdMax"`
	Conntrack    float64 `json:"conntrack"`
	DriftMs      float64 `json:"driftMs"`
	OOMKills     float64 `json:"oomKills"`
	ScrapeMs     float64 `json:"scrapeMs"`

	Series map[string][]float64 `json:"series"`
}

type filesystem struct {
	Mount  string  `json:"mount"`
	Device string  `json:"device"`
	Fstype string  `json:"fstype"`
	Used   float64 `json:"used"`
	Size   float64 `json:"size"`
	Pct    float64 `json:"pct"`
}

// a 3m window smooths the 15s scrape enough that a single slow scrape does not
// show up as a spike, while still reacting inside one refresh
const rateWindow = "3m"

var instantQueries = map[string]string{
	"up":        `up{job="node"}`,
	"scrape":    `scrape_duration_seconds{job="node"}`,
	"uname":     `node_uname_info`,
	"uptime":    `time() - node_boot_time_seconds`,
	"cores":     `count by (host) (node_cpu_seconds_total{mode="idle"})`,
	"cpu":       `100 - avg by (host) (rate(node_cpu_seconds_total{mode="idle"}[` + rateWindow + `])) * 100`,
	"core":      `100 - rate(node_cpu_seconds_total{mode="idle"}[` + rateWindow + `]) * 100`,
	"iowait":    `avg by (host) (rate(node_cpu_seconds_total{mode="iowait"}[` + rateWindow + `])) * 100`,
	"freq":      `avg by (host) (node_cpu_scaling_frequency_hertz)`,
	"governor":  `node_cpu_scaling_governor == 1`,
	"load1":     `node_load1`,
	"load5":     `node_load5`,
	"load15":    `node_load15`,
	"memTotal":  `node_memory_MemTotal_bytes`,
	"memAvail":  `node_memory_MemAvailable_bytes`,
	"memCached": `node_memory_Cached_bytes`,
	"swapTotal": `node_memory_SwapTotal_bytes`,
	"swapFree":  `node_memory_SwapFree_bytes`,
	"fsSize":    `node_filesystem_size_bytes{fstype!~"tmpfs|ramfs|squashfs|overlay|devtmpfs|autofs"}`,
	"fsAvail":   `node_filesystem_avail_bytes{fstype!~"tmpfs|ramfs|squashfs|overlay|devtmpfs|autofs"}`,
	"diskRead":  `sum by (host) (rate(node_disk_read_bytes_total[` + rateWindow + `]))`,
	"diskWrite": `sum by (host) (rate(node_disk_written_bytes_total[` + rateWindow + `]))`,
	"netRx":     `sum by (host) (rate(node_network_receive_bytes_total{device!~"lo|tailscale0"}[` + rateWindow + `]))`,
	"netTx":     `sum by (host) (rate(node_network_transmit_bytes_total{device!~"lo|tailscale0"}[` + rateWindow + `]))`,
	"netRxAll":  `sum by (host) (node_network_receive_bytes_total{device!~"lo|tailscale0"})`,
	"netTxAll":  `sum by (host) (node_network_transmit_bytes_total{device!~"lo|tailscale0"})`,
	"netErrs":   `sum by (host) (node_network_receive_errs_total{device!~"lo"} + node_network_transmit_errs_total{device!~"lo"})`,
	"netUp":     `node_network_up == 1`,
	"temp":      `max by (host) (node_thermal_zone_temp)`,
	"procsRun":  `node_procs_running`,
	"procsBlk":  `node_procs_blocked`,
	"ctx":       `rate(node_context_switches_total[` + rateWindow + `])`,
	"forks":     `rate(node_forks_total[` + rateWindow + `])`,
	"fdUsed":    `node_filefd_allocated`,
	"fdMax":     `node_filefd_maximum`,
	"conntrack": `node_nf_conntrack_entries`,
	"drift":     `node_timex_offset_seconds`,
	"oom":       `node_vmstat_oom_kill`,
}

var rangeQueries = map[string]string{
	"cpu":   `100 - avg by (host) (rate(node_cpu_seconds_total{mode="idle"}[` + rateWindow + `])) * 100`,
	"mem":   `(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100`,
	"temp":  `max by (host) (node_thermal_zone_temp)`,
	"load":  `node_load1`,
	"netRx": `sum by (host) (rate(node_network_receive_bytes_total{device!~"lo|tailscale0"}[` + rateWindow + `]))`,
	"netTx": `sum by (host) (rate(node_network_transmit_bytes_total{device!~"lo|tailscale0"}[` + rateWindow + `]))`,
	"disk":  `sum by (host) (rate(node_disk_read_bytes_total[` + rateWindow + `]) + rate(node_disk_written_bytes_total[` + rateWindow + `]))`,
}

func collectHosts(ctx context.Context, vm *vmClient, cat catalog, cfg config) []hostStats {
	now := time.Now()

	q := vm.batch(ctx, instantQueries)
	series := vm.batchRange(ctx, rangeQueries, now.Add(-cfg.lookback), now, cfg.step)

	var (
		up        = byHost(q["up"])
		scrape    = byHost(q["scrape"])
		uname     = byHostSamples(q["uname"])
		uptime    = byHost(q["uptime"])
		cores     = byHost(q["cores"])
		cpu       = byHost(q["cpu"])
		core      = byHostLabel(q["core"], "cpu")
		iowait    = byHost(q["iowait"])
		freq      = byHost(q["freq"])
		governor  = byHostSamples(q["governor"])
		load1     = byHost(q["load1"])
		load5     = byHost(q["load5"])
		load15    = byHost(q["load15"])
		memTotal  = byHost(q["memTotal"])
		memAvail  = byHost(q["memAvail"])
		memCached = byHost(q["memCached"])
		swapTotal = byHost(q["swapTotal"])
		swapFree  = byHost(q["swapFree"])
		fsSize    = byHostSamples(q["fsSize"])
		fsAvail   = byHostLabel(q["fsAvail"], "mountpoint")
		diskRead  = byHost(q["diskRead"])
		diskWrite = byHost(q["diskWrite"])
		netRx     = byHost(q["netRx"])
		netTx     = byHost(q["netTx"])
		netRxAll  = byHost(q["netRxAll"])
		netTxAll  = byHost(q["netTxAll"])
		netErrs   = byHost(q["netErrs"])
		netUp     = byHostSamples(q["netUp"])
		temp      = byHost(q["temp"])
		procsRun  = byHost(q["procsRun"])
		procsBlk  = byHost(q["procsBlk"])
		ctxSw     = byHost(q["ctx"])
		forks     = byHost(q["forks"])
		fdUsed    = byHost(q["fdUsed"])
		fdMax     = byHost(q["fdMax"])
		conntrack = byHost(q["conntrack"])
		drift     = byHost(q["drift"])
		oom       = byHost(q["oom"])
	)

	out := make([]hostStats, 0, len(cat.Hosts))
	for _, meta := range cat.Hosts {
		name := meta.Name
		h := hostStats{
			Name:      name,
			Role:      meta.Role,
			Blurb:     meta.Blurb,
			Glyph:     meta.Glyph,
			Accent:    meta.Accent,
			AccentAlt: meta.AccentAlt,
			LAN:       meta.LAN,
			Model:     meta.Model,

			Online: up[name] == 1,

			UptimeSec: uptime[name],
			Cores:     int(cores[name]),
			CPUPct:    clampPct(cpu[name]),
			IOWaitPct: clampPct(iowait[name]),
			FreqMHz:   freq[name] / 1e6,
			Load1:     load1[name],
			Load5:     load5[name],
			Load15:    load15[name],

			MemTotal:  memTotal[name],
			MemCached: memCached[name],
			SwapTotal: swapTotal[name],

			DiskReadBps:  diskRead[name],
			DiskWriteBps: diskWrite[name],
			NetRxBps:     netRx[name],
			NetTxBps:     netTx[name],
			NetRxTotal:   netRxAll[name],
			NetTxTotal:   netTxAll[name],
			NetErrs:      netErrs[name],

			TempC: temp[name],

			ProcsRunning: procsRun[name],
			ProcsBlocked: procsBlk[name],
			CtxSwitches:  ctxSw[name],
			Forks:        forks[name],
			FdUsed:       fdUsed[name],
			FdMax:        fdMax[name],
			Conntrack:    conntrack[name],
			DriftMs:      drift[name] * 1000,
			OOMKills:     oom[name],
			ScrapeMs:     scrape[name] * 1000,
		}

		h.MemUsed = h.MemTotal - memAvail[name]
		if h.MemTotal > 0 {
			h.MemPct = clampPct(h.MemUsed / h.MemTotal * 100)
		}
		h.SwapUsed = h.SwapTotal - swapFree[name]

		if info := uname[name]; len(info) > 0 {
			h.Kernel = info[0].label("release")
			h.Arch = info[0].label("machine")
		}
		if g := governor[name]; len(g) > 0 {
			h.Governor = g[0].label("governor")
		}
		if devices := netUp[name]; len(devices) > 0 {
			names := make([]string, 0, len(devices))
			for _, d := range devices {
				if dev := d.label("device"); dev != "" && dev != "lo" {
					names = append(names, dev)
				}
			}
			sort.Strings(names)
			if len(names) > 0 {
				h.NetDevice = names[0]
			}
		}

		// per core usage, ordered by the cpu label read as a number so cpu10
		// does not sort between cpu1 and cpu2
		if percore := core[name]; len(percore) > 0 {
			keys := make([]string, 0, len(percore))
			for k := range percore {
				keys = append(keys, k)
			}
			sort.Slice(keys, func(i, j int) bool { return atoiSafe(keys[i]) < atoiSafe(keys[j]) })
			for _, k := range keys {
				h.CorePct = append(h.CorePct, round(clampPct(percore[k]), 1))
			}
		}

		for _, s := range fsSize[name] {
			mount := s.label("mountpoint")
			size := s.value
			if mount == "" || size <= 0 {
				continue
			}
			used := size - fsAvail[name][mount]
			fs := filesystem{
				Mount:  mount,
				Device: s.label("device"),
				Fstype: s.label("fstype"),
				Used:   used,
				Size:   size,
				Pct:    clampPct(used / size * 100),
			}
			h.Filesystems = append(h.Filesystems, fs)
			if mount == "/" {
				h.DiskPct = fs.Pct
			}
		}
		sort.Slice(h.Filesystems, func(i, j int) bool { return h.Filesystems[i].Mount < h.Filesystems[j].Mount })

		h.Series = map[string][]float64{}
		for key, perHost := range series {
			if values, ok := perHost[name]; ok {
				h.Series[key] = values
			}
		}

		out = append(out, h)
	}
	return out
}

func clampPct(v float64) float64 {
	if v < 0 {
		return 0
	}
	if v > 100 {
		return 100
	}
	return v
}

func atoiSafe(s string) int {
	n := 0
	for _, r := range s {
		if r < '0' || r > '9' {
			return n
		}
		n = n*10 + int(r-'0')
	}
	return n
}
