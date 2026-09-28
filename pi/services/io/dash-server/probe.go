package main

import (
	"context"
	"crypto/tls"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"
)

type serviceStatus struct {
	Name   string `json:"name"`
	Host   string `json:"host"`
	Blurb  string `json:"blurb"`
	Link   string `json:"link"`
	Detail string `json:"detail"`

	// state is one of up, down or unprobed
	State     string  `json:"state"`
	LatencyMs float64 `json:"latencyMs"`
	Code      int     `json:"code"`
	Note      string  `json:"note"`
}

type prober struct {
	http    *http.Client
	timeout time.Duration
}

func newProber(timeout time.Duration) *prober {
	return &prober{
		timeout: timeout,
		http: &http.Client{
			Timeout: timeout,
			// every name here is either loopback, tailnet or a real public
			// cert; a redirect to a login page still proves the thing answers,
			// so follow nothing and judge the first response
			CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
			Transport: &http.Transport{
				TLSClientConfig:     &tls.Config{InsecureSkipVerify: true},
				DisableKeepAlives:   true,
				TLSHandshakeTimeout: timeout,
			},
		},
	}
}

func (p *prober) probeAll(ctx context.Context, services []catalogService) []serviceStatus {
	out := make([]serviceStatus, len(services))
	var wg sync.WaitGroup
	for i, svc := range services {
		out[i] = serviceStatus{
			Name:   svc.Name,
			Host:   svc.Host,
			Blurb:  svc.Blurb,
			Link:   svc.Link,
			Detail: svc.Detail,
			State:  "unprobed",
		}
		if svc.Probe == "" {
			continue
		}
		wg.Add(1)
		go func(i int, target string) {
			defer wg.Done()
			p.probe(ctx, target, &out[i])
		}(i, svc.Probe)
	}
	wg.Wait()
	return out
}

func (p *prober) probe(ctx context.Context, target string, into *serviceStatus) {
	start := time.Now()

	if rest, ok := strings.CutPrefix(target, "tcp://"); ok {
		dialer := net.Dialer{Timeout: p.timeout}
		conn, err := dialer.DialContext(ctx, "tcp", rest)
		into.LatencyMs = round(float64(time.Since(start).Microseconds())/1000, 1)
		if err != nil {
			into.State = "down"
			into.Note = shortErr(err)
			return
		}
		conn.Close()
		into.State = "up"
		return
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, target, nil)
	if err != nil {
		into.State = "down"
		into.Note = shortErr(err)
		return
	}
	req.Header.Set("User-Agent", "dash/probe")

	res, err := p.http.Do(req)
	into.LatencyMs = round(float64(time.Since(start).Microseconds())/1000, 1)
	if err != nil {
		into.State = "down"
		into.Note = shortErr(err)
		return
	}
	res.Body.Close()

	into.Code = res.StatusCode
	// transmission answers 409 without a session id and adguard answers 401
	// without a login: both mean "the daemon is up and talking", which is all
	// this probe claims to know
	if res.StatusCode >= 500 {
		into.State = "down"
		into.Note = res.Status
		return
	}
	into.State = "up"
}

// shortErr trims the dial/url wrapper noise so the card can show the reason
func shortErr(err error) string {
	msg := err.Error()
	if i := strings.LastIndex(msg, ": "); i >= 0 && len(msg)-i < 60 {
		msg = msg[i+2:]
	}
	if len(msg) > 60 {
		msg = msg[:57] + "..."
	}
	return msg
}
