package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strconv"
	"sync"
	"time"
)

type vmClient struct {
	baseURL string
	http    *http.Client
}

func newVMClient(baseURL string) *vmClient {
	return &vmClient{
		baseURL: baseURL,
		http: &http.Client{
			Timeout:   15 * time.Second,
			Transport: &http.Transport{MaxIdleConnsPerHost: 8},
		},
	}
}

type promResponse struct {
	Status string `json:"status"`
	Error  string `json:"error"`
	Data   struct {
		Result []struct {
			Metric map[string]string `json:"metric"`
			Value  [2]any            `json:"value"`
			Values [][2]any          `json:"values"`
		} `json:"result"`
	} `json:"data"`
}

type sample struct {
	labels map[string]string
	value  float64
}

func (s sample) label(name string) string { return s.labels[name] }

// instant runs an instant query and keeps every label, so the caller can group
// by host, mountpoint, cpu, device, whatever the query actually returned
func (c *vmClient) instant(ctx context.Context, query string) ([]sample, error) {
	resp, err := c.get(ctx, "/api/v1/query", url.Values{"query": {query}})
	if err != nil {
		return nil, err
	}
	out := make([]sample, 0, len(resp.Data.Result))
	for _, series := range resp.Data.Result {
		if v, ok := scalarValue(series.Value); ok {
			out = append(out, sample{labels: series.Metric, value: v})
		}
	}
	return out, nil
}

// rangeByHost runs a range query and returns each host's values in time order
func (c *vmClient) rangeByHost(ctx context.Context, query string, start, end time.Time, step time.Duration) (map[string][]float64, error) {
	resp, err := c.get(ctx, "/api/v1/query_range", url.Values{
		"query": {query},
		"start": {strconv.FormatInt(start.Unix(), 10)},
		"end":   {strconv.FormatInt(end.Unix(), 10)},
		"step":  {step.String()},
	})
	if err != nil {
		return nil, err
	}
	out := make(map[string][]float64, len(resp.Data.Result))
	for _, s := range resp.Data.Result {
		host := s.Metric["host"]
		if host == "" {
			continue
		}
		values := make([]float64, 0, len(s.Values))
		for _, point := range s.Values {
			if v, ok := scalarValue(point); ok {
				values = append(values, v)
			}
		}
		out[host] = values
	}
	return out, nil
}

func (c *vmClient) get(ctx context.Context, path string, query url.Values) (*promResponse, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.baseURL+path+"?"+query.Encode(), nil)
	if err != nil {
		return nil, err
	}
	res, err := c.http.Do(req)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()

	var out promResponse
	if err := json.NewDecoder(res.Body).Decode(&out); err != nil {
		return nil, err
	}
	if out.Status != "success" {
		return nil, fmt.Errorf("victoriametrics: %s", out.Error)
	}
	return &out, nil
}

// scalarValue reads a prometheus [timestamp, "value"] pair
func scalarValue(pair [2]any) (float64, bool) {
	s, ok := pair[1].(string)
	if !ok {
		return 0, false
	}
	v, err := strconv.ParseFloat(s, 64)
	return v, err == nil
}

// batch runs a named set of instant queries concurrently. the page needs
// around twenty of them and VictoriaMetrics answers each in a couple of
// milliseconds, so doing them in sequence would spend more time on round trips
// than on work. a single failure is not fatal: that panel just comes back
// empty rather than blanking the whole dashboard.
func (c *vmClient) batch(ctx context.Context, queries map[string]string) map[string][]sample {
	var (
		mu   sync.Mutex
		wg   sync.WaitGroup
		out  = make(map[string][]sample, len(queries))
		gate = make(chan struct{}, 8)
	)
	for name, query := range queries {
		wg.Add(1)
		go func(name, query string) {
			defer wg.Done()
			gate <- struct{}{}
			defer func() { <-gate }()

			res, err := c.instant(ctx, query)
			if err != nil {
				logOnce("vm query "+name, err)
				return
			}
			mu.Lock()
			out[name] = res
			mu.Unlock()
		}(name, query)
	}
	wg.Wait()
	return out
}

// batchRange is the same idea for the sparkline history
func (c *vmClient) batchRange(ctx context.Context, queries map[string]string, start, end time.Time, step time.Duration) map[string]map[string][]float64 {
	var (
		mu   sync.Mutex
		wg   sync.WaitGroup
		out  = make(map[string]map[string][]float64, len(queries))
		gate = make(chan struct{}, 4)
	)
	for name, query := range queries {
		wg.Add(1)
		go func(name, query string) {
			defer wg.Done()
			gate <- struct{}{}
			defer func() { <-gate }()

			res, err := c.rangeByHost(ctx, query, start, end, step)
			if err != nil {
				logOnce("vm range "+name, err)
				return
			}
			mu.Lock()
			out[name] = res
			mu.Unlock()
		}(name, query)
	}
	wg.Wait()
	return out
}
