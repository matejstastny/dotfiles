# io services

`ytdl`, `share`, `jellyfin`, `transmission-daemon`, `node-exporter`,
`victoria-metrics` and `dash` on io, all reachable only from the tailnet
and the house lan.

## shape

- `server/` — go service backing ytdl, stdlib only. runs yt-dlp and ffmpeg,
  streams progress over SSE, owns the cache and its 20 GB cap. the built ui is
  embedded into the binary with `go:embed`, so io needs neither node nor a
  static web root.
- `web/` — astro + vanilla ts, builds into `server/dist/`. same palette and
  font as elara.boo, io's purple accent from `pi/hosts/io.toml`.
- `share-server/` — go service backing quickshare, stdlib only. same
  `go:embed` shape as `server/`, keeps at most `SHARE_MAX_FILES` uploads and
  evicts the oldest once a new one lands.
- `share-web/` — astro + vanilla ts, builds into `share-server/dist/`. same
  layout system as `web/`, just the one page.
- `dash-server/` — go service backing the fleet dashboard, stdlib only.
  queries VictoriaMetrics' HTTP API, probes every service in the catalog,
  reads detail out of adguard, transmission, jellyfin, ytdl, share and
  tailscale, caches all of it and serves it as JSON at `/api/stats`. same
  `go:embed` shape as `server/` and `share-server/`.
- `dash-server/catalog.json` — the one hand written description of the fleet:
  hosts (role, accent, lan address, board) and services (blurb, public link,
  what to probe). embedded into the binary as a fallback and also installed to
  `/etc/dash/catalog.json`, so a new service is an edit plus a restart rather
  than a rebuild.
- `dash-web/` — astro + vanilla ts, builds into `dash-server/dist/`. one
  full-bleed page, one module per panel under `src/scripts/panels/`, all
  charts hand-rolled inline SVG and CSS, no charting library.
- `prepare` — builds the ytdl, share and dash binaries and uis, on this
  machine, into `build/` (linux/arm64). jellyfin and transmission are apk
  packages, nothing to build.
- `install` — runs on io: apk deps, users, dirs, openrc services, caddy.
- `jellyfin.confd` — the one line jellyfin's default conf.d needs changed
  (turns the bundled web client back on).
- `transmission-settings.json` — seeded into transmission's config dir on
  first run only; transmission owns the file after that.
- `transmission-done` — transmission's `script-torrent-done` hook, hardlinks
  finished videos into jellyfin's library.
- `scrape.yml` — VictoriaMetrics' scrape targets: node-exporter on thebe,
  leda and io itself, one `host` label each.
- `victoria-metrics.confd` — points VictoriaMetrics at `scrape.yml`, sets a
  90 day retention. node-exporter needs no config changes from its apk
  default, so this is the only apk confd override in the metrics stack.
- `dash.initd` / `dash.confd` — dash is a custom-built binary like ytdl and
  share, not an apk package, so it needs its own openrc unit rather than an
  override. `dash.confd` sets the loopback listen address, the catalog path,
  the sparkline window (`DASH_LOOKBACK`, `DASH_STEP`), the three refresh
  cadences and the urls of every service api it reads. it also sources
  `/etc/dash/dash.env` for the one secret it needs (see "the manual bits").

## deploying

```sh
bin/pi sync io --services
```

that runs `prepare` here, pushes the binaries and configs, then runs `install`
on io. needs `pnpm` and `go` locally; io needs nothing but apk.

## ytdl

youtube to mp4/mp3 with a web ui, at `yt.elara.boo`.

`keep` in the ui picks between the cache (`/var/lib/ytdl/cache`, evicted oldest
first past 20 GB) and the library (`/srv/media/{video,music}`, never evicted,
group `media` so jellyfin can read it). picking both is a hardlink, so it
costs nothing on the same filesystem.

## share

quickshare at `share.elara.boo`: drop a file in from the web ui, or run
`share <file>` on a laptop already on the tailnet. either way you get back a
`share.elara.boo/dl/<id>/<name>` link, copied to the clipboard by the script.

files live in `/var/lib/share/files`, `SHARE_MAX_FILES` (default 10) of them
at a time — the oldest is evicted the moment a new upload would push the count
over that, so it is a rolling window rather than a cache with a manual clear.
`SHARE_MAX_FILESIZE_GB` (default 5) caps any one upload. there is no auth on
the endpoint beyond network-level gating, same model as ytdl and transmission.

## jellyfin

media server at `jellyfin.elara.boo`, libraries pointed at
`/srv/media/video` and `/srv/media/music`.

- deliberately left listening on `:8096` on the lan too (not loopback-only
  like ytdl and transmission), because the tv apps' auto-discovery and
  casting want to find it directly rather than through a hostname.
- no hardware transcoding configured. io has no `/dev/dri`, and a pi 4 can't
  encode much anyway. everything ytdl and transmission bring in is already
  h264/aac, so direct play covers it — if something doesn't direct play, the
  fix is re-encoding the source, not turning on server-side transcode.
- add `/srv/media/video` as a **Home Videos** library, not Movies/Shows.
  nothing in there is named to Jellyfin's `Title (Year)` matching convention,
  so a metadata-scraping library type just shows a wall of unmatched titles.

## transmission

bittorrent client at `torrent.elara.boo`, rpc bound to loopback and fronted by
caddy the same way ytdl is. the rpc has no login of its own — network-level
gating (loopback bind + caddy's tailnet/lan allowlist) is the only thing
guarding it, matching ytdl's model.

transmission also has its own DNS-rebinding guard that checks the `Host`
header against a whitelist, independent of the ip-based one above — with it
on, going through the `torrent.elara.boo` name gets a bare `421 Misdirected
Request` instead of the ui. `rpc-host-whitelist-enabled: false` in
`transmission-settings.json` turns it off, leaving the ip-based gating above
as the only guard (same tradeoff as `rpc-whitelist-enabled: false`).

finished downloads land in `/home/elara/jellyfin` and stay there (seeding
keeps reading them) — elara's home rather than transmission's own, so she can
browse or scp them directly. group `media`, setgid, so transmission (added to
that group by install) can still write into it. in-progress downloads live
separately in `/var/lib/transmission/incomplete`, not visible there until
they finish. `transmission-done` hardlinks anything with a video extension
into `/srv/media/video` for jellyfin to pick up. multi-file torrents (season
packs, etc.) are skipped on purpose rather than guessing which member is the
real video — move those into the library by hand.

`/home/elara/torrents` is a watch directory: drop a `.torrent` file in and
transmission adds and starts it within a few seconds, deleting the original
(`trash-original-torrent-files`) once queued. on a laptop, `configs/systemd/
home-elara-torrents.mount` sshfs-mounts that same directory to `~/torrents`
locally, so saving a `.torrent` there is enough — no web ui, no scp. needs
that laptop's key in io's `~/.ssh/authorized_keys` (not tracked, added by
hand the same way the caddy env token is) so the mount doesn't sit there
asking for a password.

## metrics

`node-exporter` runs on thebe, leda and io (see each host's own `install`),
each exposing a `/metrics` endpoint on `:9100` with that box's CPU, memory,
disk and temperature. `victoria-metrics` on io scrapes all three over the
tailnet every 15s (`scrape.yml`) and keeps 90 days of history, bound to
loopback since only `dash` on the same box needs to query it.

`dash` was tried first as Grafana, which turned out to be a lot more than
this needed — a login, a plugin system, dashboard JSON to hand-tune. What
replaced it is one page at `dash.elara.boo` with no login, because there is
nothing here to change, only to read.

it pulls from four kinds of source, on three separate schedules, into three
separate caches, so a slow one never holds up the others:

- **victoria-metrics, every 15s.** around forty PromQL queries fired
  concurrently, each one covering all three hosts at once rather than one
  query per host: cpu (total and per core), load, memory, swap, every real
  filesystem, disk io, network throughput and totals, temperature, process
  and context-switch counters, file descriptors, conntrack, clock drift, oom
  kills and scrape health. plus seven range queries for the sparklines.
- **service probes, every 20s.** every entry in `catalog.json` with a
  `probe` gets a tcp connect or an http GET and is timed. anything under a
  500 counts as up, because transmission answers 409 and adguard answers 401
  to an unauthenticated poke, and both mean the daemon is alive.
- **service apis, every 20s.** adguard's query and block counts, hourly
  histogram and top domains/clients; transmission's session stats and
  torrent list; jellyfin's version; ytdl's cache and recent files; share's
  slots; victoria-metrics' own series and disk figures.
- **tailscale, every 15s.** `tailscale status --json` for the peer table:
  who is online, tailnet address, whether the path is direct or through a
  derp relay, per-peer traffic, exit node and subnet routes. this is also
  where each host's tailnet address on its card comes from, and it is what
  lets the adguard panel relabel `100.88.10.68` as the node it belongs to.

the browser polls `/api/stats` every 5s and only redraws when the payload's
`generatedAt` actually moved, so the page stays current without rebuilding
the dom three times for the same numbers.

warn thresholds match the ones already in the pi prompt
(`pi/config/starship/prompt.toml`): cpu temp over 70°C, memory over 85%, so
the same numbers mean the same thing whether you're looking at a terminal
or the dashboard. the temp gauge is drawn against 80°C rather than 100,
because that is where a pi 4 starts throttling.

## the manual bits

all live secrets or live state, so none of it is tracked here:

1. `/etc/caddy/caddy.env` on io with `CF_API_TOKEN=<cloudflare token>`, for the
   DNS-01 cert. same token thebe uses.
2. DNS rewrites in AdGuard Home: `yt.elara.boo`, `share.elara.boo`,
   `jellyfin.elara.boo`, `torrent.elara.boo` and `dash.elara.boo` → io's
   Tailscale address.
3. jellyfin's first-run setup wizard (admin account, add the two libraries) —
   inherently a one-time manual step, visit `jellyfin.elara.boo` after install.
4. any laptop's public key in io's `~/.ssh/authorized_keys`, for a passwordless
   `~/torrents` sshfs mount (see `home-elara-torrents.mount` below):
   ```sh
   ssh-copy-id elara@io   # or: cat ~/.ssh/id_ed25519.pub | ssh io 'cat >> ~/.ssh/authorized_keys'
   ```
5. `/etc/dash/dash.env` with `DASH_ADGUARD_PASS=<the adguard web password>`.
   AdGuard Home has no API tokens, only the web login, so this is the one
   secret dash needs. without it the dns panel stays empty and everything
   else on the page still works:
   ```sh
   ssh io 'sudo sh -c "umask 077; cat > /etc/dash/dash.env"'
   # paste DASH_ADGUARD_PASS=<password>, Enter, Ctrl-D
   ssh io 'sudo rc-service dash restart'
   ```
6. `/var/lib/ytdl/cookies.txt`, optional but needed for anything YouTube age
   or bot gates (error says "Sign in to confirm your age" or similar). export
   a Netscape-format cookies.txt from a logged-in browser (a "Get cookies.txt"
   extension) and put it there:
   ```sh
   scp cookies.txt io:/tmp/cookies.txt
   ssh io 'sudo install -o ytdl -g ytdl -m 600 /tmp/cookies.txt /var/lib/ytdl/cookies.txt && rm /tmp/cookies.txt'
   ```
   these cookies are a real logged-in session, so treat the file like a
   password: `600`, owned by `ytdl`, never committed. YouTube rotates the
   values it cares about over time, so a stale file starts failing again
   eventually and just needs re-exporting.

## working on it

```sh
cd server && go run .            # api on :8090, serves whatever is in dist/
cd web && pnpm dev               # ui on :4321, proxies /api to :8090

cd share-server && go run .      # api on :8091, serves whatever is in dist/
cd share-web && pnpm dev         # ui on :4322, proxies /api and /dl to :8091

cd dash-server && go run .       # api on :8092, serves whatever is in dist/
cd dash-web && pnpm dev          # ui on :4323, proxies /api to :8092
```
