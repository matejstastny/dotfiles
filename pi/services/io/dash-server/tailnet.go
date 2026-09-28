package main

import (
	"context"
	"encoding/json"
	"os/exec"
	"sort"
	"strings"
	"time"
)

type tailnet struct {
	Backend string     `json:"backend"`
	Version string     `json:"version"`
	SelfIP  string     `json:"selfIp"`
	Domain  string     `json:"domain"`
	Peers   []tailPeer `json:"peers"`
	Online  int        `json:"online"`
	Total   int        `json:"total"`
}

type tailPeer struct {
	Name     string  `json:"name"`
	OS       string  `json:"os"`
	IP       string  `json:"ip"`
	Online   bool    `json:"online"`
	Self     bool    `json:"self"`
	ExitNode bool    `json:"exitNode"`
	Offers   bool    `json:"offersExit"`
	Relay    string  `json:"relay"`
	Direct   string  `json:"direct"`
	Routes   string  `json:"routes"`
	RxBytes  float64 `json:"rxBytes"`
	TxBytes  float64 `json:"txBytes"`
	LastSeen string  `json:"lastSeen"`
}

type tsNode struct {
	HostName       string   `json:"HostName"`
	DNSName        string   `json:"DNSName"`
	OS             string   `json:"OS"`
	TailscaleIPs   []string `json:"TailscaleIPs"`
	Online         bool     `json:"Online"`
	ExitNode       bool     `json:"ExitNode"`
	ExitNodeOption bool     `json:"ExitNodeOption"`
	Relay          string   `json:"Relay"`
	CurAddr        string   `json:"CurAddr"`
	PrimaryRoutes  []string `json:"PrimaryRoutes"`
	RxBytes        float64  `json:"RxBytes"`
	TxBytes        float64  `json:"TxBytes"`
	LastSeen       string   `json:"LastSeen"`
}

// collectTailnet shells out rather than talking to the local api socket
// directly: the socket needs the same permissions either way, and `tailscale
// status --json` is the one interface here that is actually stable.
func collectTailnet(ctx context.Context, bin string) (*tailnet, error) {
	ctx, cancel := context.WithTimeout(ctx, 8*time.Second)
	defer cancel()

	out, err := exec.CommandContext(ctx, bin, "status", "--json").Output()
	if err != nil {
		return nil, err
	}

	var raw struct {
		Version        string            `json:"Version"`
		BackendState   string            `json:"BackendState"`
		MagicDNSSuffix string            `json:"MagicDNSSuffix"`
		Self           tsNode            `json:"Self"`
		Peer           map[string]tsNode `json:"Peer"`
	}
	if err := json.Unmarshal(out, &raw); err != nil {
		return nil, err
	}

	net := &tailnet{
		Backend: raw.BackendState,
		Version: strings.SplitN(raw.Version, "-", 2)[0],
		Domain:  raw.MagicDNSSuffix,
	}
	if len(raw.Self.TailscaleIPs) > 0 {
		net.SelfIP = raw.Self.TailscaleIPs[0]
	}

	add := func(n tsNode, self bool) {
		p := tailPeer{
			Name:     n.HostName,
			OS:       n.OS,
			Online:   n.Online || self,
			Self:     self,
			ExitNode: n.ExitNode,
			Offers:   n.ExitNodeOption,
			Relay:    n.Relay,
			Routes:   strings.Join(n.PrimaryRoutes, " "),
			RxBytes:  n.RxBytes,
			TxBytes:  n.TxBytes,
		}
		if len(n.TailscaleIPs) > 0 {
			p.IP = n.TailscaleIPs[0]
		}
		// CurAddr is the endpoint the wireguard session actually landed on, so
		// for a peer on the same wifi it reads as the lan address, which is
		// exactly the "am I going direct or through a relay" answer
		if n.CurAddr != "" {
			p.Direct = n.CurAddr
		}
		// tailscale writes the zero time for a peer that is online right now
		if t, err := time.Parse(time.RFC3339, n.LastSeen); err == nil && !t.IsZero() && t.Year() > 1 {
			p.LastSeen = t.UTC().Format(time.RFC3339)
		}
		net.Peers = append(net.Peers, p)
	}

	add(raw.Self, true)
	for _, peer := range raw.Peer {
		add(peer, false)
	}

	sort.SliceStable(net.Peers, func(i, j int) bool {
		a, b := net.Peers[i], net.Peers[j]
		if a.Online != b.Online {
			return a.Online
		}
		return a.Name < b.Name
	})

	net.Total = len(net.Peers)
	for _, p := range net.Peers {
		if p.Online {
			net.Online++
		}
	}
	return net, nil
}
