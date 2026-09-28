package main

import "time"

type statsResponse struct {
	GeneratedAt  time.Time       `json:"generatedAt"`
	Window       window          `json:"window"`
	Fleet        fleetSummary    `json:"fleet"`
	Hosts        []hostStats     `json:"hosts"`
	Services     []serviceStatus `json:"services"`
	Integrations integrations    `json:"integrations"`
	Tailnet      *tailnet        `json:"tailnet"`
}

type window struct {
	Lookback string `json:"lookback"`
	Step     string `json:"step"`
}

type fleetSummary struct {
	HostsUp    int `json:"hostsUp"`
	HostsTotal int `json:"hostsTotal"`

	ServicesUp       int `json:"servicesUp"`
	ServicesDown     int `json:"servicesDown"`
	ServicesUnprobed int `json:"servicesUnprobed"`
	ServicesTotal    int `json:"servicesTotal"`

	Cores     int     `json:"cores"`
	CPUPct    float64 `json:"cpuPct"`
	MemUsed   float64 `json:"memUsed"`
	MemTotal  float64 `json:"memTotal"`
	DiskUsed  float64 `json:"diskUsed"`
	DiskTotal float64 `json:"diskTotal"`
	NetRxBps  float64 `json:"netRxBps"`
	NetTxBps  float64 `json:"netTxBps"`

	MaxTempC    float64 `json:"maxTempC"`
	HottestHost string  `json:"hottestHost"`

	// the shortest uptime in the fleet, which is the one worth showing: it is
	// whichever box rebooted most recently
	YoungestSec  float64 `json:"youngestSec"`
	YoungestHost string  `json:"youngestHost"`

	Warnings []string `json:"warnings"`
}

// warn thresholds, the same ones the pi shell prompt uses
const (
	warnTempC   = 70
	warnMemPct  = 85
	warnDiskPct = 85
	warnCPUPct  = 90
)

func summarise(hosts []hostStats, services []serviceStatus) fleetSummary {
	f := fleetSummary{HostsTotal: len(hosts), ServicesTotal: len(services)}

	var cpuSum float64
	var cpuHosts int
	for _, h := range hosts {
		if !h.Online {
			f.Warnings = append(f.Warnings, h.Name+" is not reporting")
			continue
		}
		f.HostsUp++
		f.Cores += h.Cores
		cpuSum += h.CPUPct
		cpuHosts++

		f.MemUsed += h.MemUsed
		f.MemTotal += h.MemTotal
		f.NetRxBps += h.NetRxBps
		f.NetTxBps += h.NetTxBps

		for _, fs := range h.Filesystems {
			// only the root filesystem counts toward the fleet total, the
			// 300 MB boot partitions would just be noise in a TB figure
			if fs.Mount == "/" {
				f.DiskUsed += fs.Used
				f.DiskTotal += fs.Size
			}
		}

		if h.TempC > f.MaxTempC {
			f.MaxTempC, f.HottestHost = h.TempC, h.Name
		}
		if h.UptimeSec > 0 && (f.YoungestSec == 0 || h.UptimeSec < f.YoungestSec) {
			f.YoungestSec, f.YoungestHost = h.UptimeSec, h.Name
		}

		if h.TempC > warnTempC {
			f.Warnings = append(f.Warnings, h.Name+" is running hot")
		}
		if h.MemPct > warnMemPct {
			f.Warnings = append(f.Warnings, h.Name+" is low on memory")
		}
		if h.DiskPct > warnDiskPct {
			f.Warnings = append(f.Warnings, h.Name+" is low on disk")
		}
		if h.CPUPct > warnCPUPct {
			f.Warnings = append(f.Warnings, h.Name+" is pinned")
		}
		if h.OOMKills > 0 {
			f.Warnings = append(f.Warnings, h.Name+" has killed something for memory")
		}
	}
	if cpuHosts > 0 {
		f.CPUPct = cpuSum / float64(cpuHosts)
	}

	for _, s := range services {
		switch s.State {
		case "up":
			f.ServicesUp++
		case "down":
			f.ServicesDown++
			f.Warnings = append(f.Warnings, s.Name+" on "+s.Host+" is down")
		default:
			f.ServicesUnprobed++
		}
	}
	return f
}
