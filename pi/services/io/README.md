# io services

the storage and application pi. its services are only reachable on the house
lan and tailnet.

- `server/` + `web/` is the ytdl service.
- `share-server/` + `share-web/` is quickshare.
- `dash-server/` + `dash-web/` is the fleet dashboard.
- `Caddyfile`, `*.initd`, `*.confd`, and `scrape.yml` are the host services.
- `prepare` cross-builds the three go binaries for linux arm64.
- `install` installs the staged service payload on io.

develop a web app with `pnpm dev` in its `*-web` directory, and its api with
`go run .` in the matching server directory. deploy from the repo root:

```sh
bin/pi sync io --services
```
