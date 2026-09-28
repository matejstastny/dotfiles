# io services

`ytdl`, `share`, `jellyfin` and `transmission-daemon` on io, all reachable only
from the tailnet and the house lan.

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
- `prepare` — builds the ytdl and share binaries and uis, on this machine,
  into `build/ytdl` and `build/share` (linux/arm64). jellyfin and transmission
  are apk packages, nothing to build.
- `install` — runs on io: apk deps, users, dirs, openrc services, caddy.
- `jellyfin.confd` — the one line jellyfin's default conf.d needs changed
  (turns the bundled web client back on).
- `transmission-settings.json` — seeded into transmission's config dir on
  first run only; transmission owns the file after that.
- `transmission-done` — transmission's `script-torrent-done` hook, hardlinks
  finished videos into jellyfin's library.

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

## the manual bits

all live secrets or live state, so none of it is tracked here:

1. `/etc/caddy/caddy.env` on io with `CF_API_TOKEN=<cloudflare token>`, for the
   DNS-01 cert. same token thebe uses.
2. DNS rewrites in AdGuard Home: `yt.elara.boo`, `share.elara.boo`,
   `jellyfin.elara.boo` and `torrent.elara.boo` → io's Tailscale address.
3. jellyfin's first-run setup wizard (admin account, add the two libraries) —
   inherently a one-time manual step, visit `jellyfin.elara.boo` after install.
4. any laptop's public key in io's `~/.ssh/authorized_keys`, for a passwordless
   `~/torrents` sshfs mount (see `home-elara-torrents.mount` below):
   ```sh
   ssh-copy-id elara@io   # or: cat ~/.ssh/id_ed25519.pub | ssh io 'cat >> ~/.ssh/authorized_keys'
   ```
5. `/var/lib/ytdl/cookies.txt`, optional but needed for anything YouTube age
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
```
