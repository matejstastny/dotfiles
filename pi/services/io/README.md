# ytdl

youtube to mp4/mp3 with a web ui, running on io at `yt.elara.boo`, reachable only
from the tailnet and the house lan.

## shape

- `server/` — go service, stdlib only. runs yt-dlp and ffmpeg, streams progress
  over SSE, owns the cache and its 20 GB cap. the built ui is embedded into the
  binary with `go:embed`, so io needs neither node nor a static web root.
- `web/` — astro + vanilla ts, builds into `server/dist/`. same palette and font
  as elara.boo, io's purple accent from `pi/hosts/io.toml`.
- `prepare` — builds both, on this machine, into `build/ytdl` (linux/arm64).
- `install` — runs on io: apk deps, users, dirs, openrc services, caddy.

## deploying

```sh
bin/pi-sync --host io --services
```

that runs `prepare` here, pushes the binary and the configs, then runs `install`
on io. needs `pnpm` and `go` locally; io needs nothing but apk.

## the manual bits

all live secrets or live state, so none of it is tracked here:

1. `/etc/caddy/caddy.env` on io with `CF_API_TOKEN=<cloudflare token>`, for the
   DNS-01 cert. same token thebe uses.
2. a DNS rewrite in AdGuard Home: `yt.elara.boo` → io's tailscale address.
3. `/var/lib/ytdl/cookies.txt`, optional but needed for anything YouTube age
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
```

## where files go

`keep` in the ui picks between the cache (`/var/lib/ytdl/cache`, evicted oldest
first past 20 GB) and the library (`/srv/media/{video,music}`, never evicted,
group `media` so jellyfin and navidrome can read it later). picking both is a
hardlink, so it costs nothing on the same filesystem.
