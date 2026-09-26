**thebe = network plane** Boring, always up, near-zero writes. You should be able to forget it exists.

|                    |                                                                                                        |
| ------------------ | ------------------------------------------------------------------------------------------------------ |
| DONE `adguardhome` | primary resolver                                                                                       |
| `unbound`          | recursive resolver behind AGH, so no upstream sees your query log                                      |
| DONE `tailscale`   | subnet router advertising `192.168.250.0/24`, full LAN from anywhere                                   |
| DONE `caddy`       | reverse proxy for everything on both pis, real names instead of `:3000`                                |
| DONE `ntfy`        | push target for your scripts; same shape as your `notify-send "✦ topic"` convention, but on your phone |

**leda = service plane** Reboot it freely, it holds the data.

|                                                             |                                                                      |
| ----------------------------------------------------------- | -------------------------------------------------------------------- |
| `adguardhome`                                               | secondary resolver                                                   |
| `syncthing`                                                 | the thing you'll actually use daily                                  |
| DONE `soju`                                                 | persistent IRC bouncer (saw the irc commit, this is the obvious fit) |
| `vaultwarden`                                               | bitwarden server, sqlite, tiny                                       |
| `victoria-metrics` + `grafana` + `prometheus-node-exporter` | metrics for both pis and the laptop                                  |
| `restic` + `rclone`                                         | nightly backup of service state offsite                              |
| DONE `tailscale`                                            | exit node, kept off thebe so bulk traffic doesn't compete with DNS   |
| `spotifyd` + ``                                             | spotify device that does airplay to the homepod mini                 |

**io = not determined** To be configured and added when use for it is found. Might have an SSD if needed

|            |                                                    |
| ---------- | -------------------------------------------------- |
| `jellyfin` | NEEDS SSD media server                             |
| `torrent`  | A torrent client, connected with jellyfin maybe?   |
| `forgejo`  | self-hosted git, so dotfiles aren't only on github |
