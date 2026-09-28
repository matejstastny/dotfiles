package main

import (
	_ "embed"
	"encoding/json"
	"fmt"
	"log"
	"os"
)

// the catalog is the only hand written description of the fleet: everything
// else on the page is measured. it ships as a file so a new service can be
// added without a rebuild, but the same bytes are embedded as a fallback so a
// missing file degrades to "slightly stale" instead of "empty dashboard".
//
//go:embed catalog.json
var defaultCatalog []byte

type catalog struct {
	Hosts    []catalogHost    `json:"hosts"`
	Services []catalogService `json:"services"`
}

type catalogHost struct {
	Name      string `json:"name"`
	Role      string `json:"role"`
	Blurb     string `json:"blurb"`
	Glyph     string `json:"glyph"`
	Accent    string `json:"accent"`
	AccentAlt string `json:"accentAlt"`
	LAN       string `json:"lan"`
	Model     string `json:"model"`
}

type catalogService struct {
	Name  string `json:"name"`
	Host  string `json:"host"`
	Blurb string `json:"blurb"`
	Link  string `json:"link"`

	// probe is either tcp://host:port or an http(s) url. an http probe counts
	// any answer below 500 as up, because several of these deliberately reply
	// 401/403/409 to an unauthenticated poke.
	Probe string `json:"probe"`

	// detail names the integration panel this service feeds, if any
	Detail string `json:"detail"`
}

func (c catalog) hostNames() []string {
	out := make([]string, 0, len(c.Hosts))
	for _, h := range c.Hosts {
		out = append(out, h.Name)
	}
	return out
}

func loadCatalog(path string) catalog {
	raw, err := os.ReadFile(path)
	if err != nil {
		if !os.IsNotExist(err) {
			log.Printf("catalog %s: %v, using the built in one", path, err)
		}
		raw = defaultCatalog
	}

	var c catalog
	if err := json.Unmarshal(raw, &c); err != nil {
		log.Printf("catalog %s: %v, using the built in one", path, err)
		if err := json.Unmarshal(defaultCatalog, &c); err != nil {
			panic(fmt.Sprintf("embedded catalog is broken: %v", err))
		}
	}
	return c
}
