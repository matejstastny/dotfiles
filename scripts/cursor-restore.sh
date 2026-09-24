#!/usr/bin/env bash
#@ restore last-picked cursor theme at startup

set -e

state="${XDG_STATE_HOME:-$HOME/.local/state}/cursor"
sizes="${XDG_STATE_HOME:-$HOME/.local/state}/cursor-sizes"
[ -f "$state" ] || exit 0

theme=$(head -n1 "$state")
[ -z "$theme" ] && exit 0

size=""
[ -f "$sizes" ] && size=$(awk -F'\t' -v t="$theme" '$1 == t { print $2 }' "$sizes")
size="${size:-24}"

hyprctl setcursor "$theme" "$size" >/dev/null
gsettings set org.gnome.desktop.interface cursor-theme "$theme" 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-size "$size" 2>/dev/null || true
