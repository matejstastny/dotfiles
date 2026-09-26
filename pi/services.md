**thebe = network plane** Global services, network-wide services, public services

|                    |                                                                                                        |
| ------------------ | ------------------------------------------------------------------------------------------------------ |
| DONE `adguardhome` | primary resolver                                                                                       |
| `unbound`          | recursive resolver behind AGH, so no upstream sees your query log                                      |
| DONE `tailscale`   | subnet router advertising `192.168.250.0/24`, full LAN from anywhere                                   |
| DONE `caddy`       | reverse proxy for everything on both pis, real names instead of `:3000`                                |
| DONE `ntfy`        | push target for your scripts; same shape as your `notify-send "✦ topic"` convention, but on your phone |

**leda = service plane** Personal local services

|                            |                                                                       |
| -------------------------- | --------------------------------------------------------------------- |
| `adguardhome`              | secondary resolver                                                    |
| `syncthing`                | the thing you'll actually use daily                                   |
| DONE `soju`                | persistent IRC bouncer (saw the irc commit, this is the obvious fit)  |
| `vaultwarden`              | bitwarden server, sqlite, tiny                                        |
| `prometheus-node-exporter` | metrics scrape target for this box, ships to `victoria-metrics` on io |
| DONE `tailscale`           | exit node, kept off thebe so bulk traffic doesn't compete with DNS    |
| `spotifyd` + ``            | spotify device that does airplay to the homepod mini                  |

**io = storage plane** Storage heavy services

|                                |                                                                                               |
| ------------------------------ | --------------------------------------------------------------------------------------------- |
| DONE `tailscale`               | joined the tailnet                                                                            |
| DONE `yt-dlp` + custom ui      | `yt.elara.boo`, mp4/mp3 with a web ui, 20 GB cache + `/srv/media` library, tailnet-only       |
| DONE `caddy`                   | reverse proxy + DNS-01 cert for `yt.elara.boo`, so bulk downloads never transit thebe        |
| `forgejo`                      | self-hosted git, moved off leda's SD card, git packs are exactly the write churn a card hates |
| `jellyfin`                     | media server, video side of the yt-dlp output                                                 |
| `navidrome`                    | streams the mp3 side of the yt-dlp output, same idea as jellyfin but audio                    |
| `torrent` client               | feeds jellyfin's library                                                                      |
| `victoria-metrics` + `grafana` | TODO                                                                                          |
