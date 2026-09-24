#!/usr/bin/env bash
#@ apply a cursor theme (+ optional size) live, remembering size per-theme for cursor-restore

set -e

theme="$1"
size="$2"
if [ -z "$theme" ]; then
	notify-send -t 3000 "✦ cursor" "no theme given"
	exit 1
fi

state="${XDG_STATE_HOME:-$HOME/.local/state}/cursor"
sizes="${XDG_STATE_HOME:-$HOME/.local/state}/cursor-sizes"
mkdir -p "$(dirname "$state")"
touch "$sizes"

if [ -z "$size" ]; then
	size=$(awk -F'\t' -v t="$theme" '$1 == t { print $2 }' "$sizes")
	size="${size:-24}"
fi

hyprctl setcursor "$theme" "$size" >/dev/null
gsettings set org.gnome.desktop.interface cursor-theme "$theme" 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-size "$size" 2>/dev/null || true

# hyprland caches the on-screen cursor image by shape *name*, not by theme/size,
# so it won't actually repaint until some surface requests a differently-named
# shape (position doesn't matter, only the name does). CursorMenu.qml forces
# that by toggling its own cursorShape after calling this script; a bare CLI
# call here has no such trick available and may visually lag until you hover
# something with a different cursor shape.

echo "$theme" >"$state"
awk -F'\t' -v t="$theme" -v s="$size" \
	'$1 == t { print t"\t"s; found=1; next } { print } END { if (!found) print t"\t"s }' \
	"$sizes" >"$sizes.tmp"
mv "$sizes.tmp" "$sizes"

notify-send -t 2000 "✦ cursor" "$theme (${size}px)"
