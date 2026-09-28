package main

import (
	"log"
	"sync"
	"time"
)

var (
	logMu   sync.Mutex
	logSeen = map[string]time.Time{}
)

// logOnce keeps a failing integration from writing the same line every refresh
// for days. the same key is only printed again after five minutes, which is
// still often enough to notice in the log but quiet enough to read.
func logOnce(key string, err error) {
	logMu.Lock()
	defer logMu.Unlock()
	if last, ok := logSeen[key]; ok && time.Since(last) < 5*time.Minute {
		return
	}
	logSeen[key] = time.Now()
	log.Printf("%s: %v", key, err)
}

func firstValue(samples []sample) float64 {
	if len(samples) == 0 {
		return 0
	}
	return samples[0].value
}

// byHost collapses a query result to one value per host
func byHost(samples []sample) map[string]float64 {
	out := make(map[string]float64, len(samples))
	for _, s := range samples {
		if h := s.label("host"); h != "" {
			out[h] = s.value
		}
	}
	return out
}

// byHostLabel groups a query result by host and then by a second label, for
// the per-core, per-filesystem and per-interface breakdowns
func byHostLabel(samples []sample, label string) map[string]map[string]float64 {
	out := map[string]map[string]float64{}
	for _, s := range samples {
		h := s.label("host")
		k := s.label(label)
		if h == "" || k == "" {
			continue
		}
		if out[h] == nil {
			out[h] = map[string]float64{}
		}
		out[h][k] = s.value
	}
	return out
}

// byHostSamples keeps the whole sample so the caller can read several labels
func byHostSamples(samples []sample) map[string][]sample {
	out := map[string][]sample{}
	for _, s := range samples {
		if h := s.label("host"); h != "" {
			out[h] = append(out[h], s)
		}
	}
	return out
}

func round(v float64, places int) float64 {
	p := 1.0
	for range places {
		p *= 10
	}
	return float64(int64(v*p+copysign(0.5, v))) / p
}

func copysign(v, sign float64) float64 {
	if sign < 0 {
		return -v
	}
	return v
}
