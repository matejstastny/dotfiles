#!/usr/bin/env bash
#@ safe hyprland launch, ran on system init

LOG="$HOME/.cache/hyprland-session.log"
mkdir -p "$HOME/.cache"
exec >>"$LOG" 2>&1
echo "=== hyprland-session start $(date) ==="

command -v uwsm >/dev/null || exec start-hyprland

# uwsm owns the session: it sources ~/.config/uwsm/env
# -g -1 disables uwsm's wait for graphical.target
# cause greetd is WantedBy that same target
exec uwsm start -g -1 -e -D Hyprland -N Hyprland start-hyprland
