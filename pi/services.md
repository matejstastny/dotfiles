**thebe = network plane** Global services, network-wide services, public services

|                                 |                                                                                                        |
| ------------------------------- | ------------------------------------------------------------------------------------------------------ |
| DONE `adguardhome`              | primary resolver                                                                                       |
| `unbound`                       | recursive resolver behind AGH, so no upstream sees your query log                                      |
| DONE `tailscale`                | subnet router advertising `192.168.250.0/24`, full LAN from anywhere                                   |
| DONE `caddy`                    | reverse proxy for everything on both pis, real names instead of `:3000`                                |
| DONE `ntfy`                     | push target for your scripts; same shape as your `notify-send "✦ topic"` convention, but on your phone |
| DONE `prometheus-node-exporter` | metrics scrape target for this box, ships to `victoria-metrics` on io                                  |

**leda = service plane** Personal local services

|                                  |                                                                          |
| -------------------------------- | ------------------------------------------------------------------------ |
| `adguardhome`                    | secondary resolver                                                       |
| DONE `soju`                      | persistent IRC bouncer (saw the irc commit, this is the obvious fit)     |
| DONE `prometheus-node-exporter`  | metrics scrape target for this box, ships to `victoria-metrics` on io    |
| DONE `tailscale`                 | exit node, kept off thebe so bulk traffic doesn't compete with DNS       |
| DONE `spotifyd` + `pyatv-bridge` | spotify connect device that relays audio via airplay to the homepod mini |

**io = storage plane** Storage heavy services

|                                  |                                                                                                               |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| DONE `tailscale`                 | joined the tailnet                                                                                            |
| DONE `yt-dlp` + custom ui        | `yt.elara.boo`, mp4/mp3 with a web ui, 20 GB cache + `/srv/media` library, tailnet-only                       |
| DONE `share` custom quickshare   | `share.elara.boo`, upload via web ui or the `share` script, keeps the last 10 files, tailnet-only             |
| DONE `caddy`                     | reverse proxy + DNS-01 cert for `yt.elara.boo`, so bulk downloads never transit thebe                         |
| DONE `jellyfin`                  | media server at `jellyfin.elara.boo`, video side of the yt-dlp output, no hw transcode                        |
| DONE `transmission-daemon`       | torrent client at `torrent.elara.boo`, `script-torrent-done` hardlinks finished video into jellyfin's library |
| DONE `prometheus-node-exporter`  | metrics scrape target for io itself, scraped over loopback                                                    |
| DONE `victoria-metrics` + `dash` | custom go+astro fleet dashboard at `dash.elara.boo`                                                           |
