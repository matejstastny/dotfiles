#!/usr/bin/env bash
set -euo pipefail

log() {
	echo -e "\033[35m==> $*\033[0m"
}

# uwsm gives the session a real graphical-session.target, which means xdg
# autostart entries and user units targeting it finally run. most of them
# duplicate quickshell or were never wanted, so turn them back off.
# the Hidden=true overrides live in configs/autostart and are symlinked by bin/link

log "Disabling sunshine autostart..."
systemctl --user disable --now app-dev.lizardbyte.app.Sunshine.service 2>/dev/null || true

log "Removing stale swww unit (wallpapers go through awww)..."
systemctl --user disable --now swww.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/swww.service"

log "Stopping xdg autostart applets for this session..."
for unit in 'app-blueman@autostart.service' 'app-nm\x2dapplet@autostart.service' \
	'app-remmina\x2dapplet@autostart.service' 'app-geoclue\x2ddemo\x2dagent@autostart.service'; do
	systemctl --user stop "$unit" 2>/dev/null || true
done

systemctl --user daemon-reload
log "Done. Overrides apply from next login."
