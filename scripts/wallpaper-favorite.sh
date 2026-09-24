#!/usr/bin/env bash
#@ toggle a wallpaper's favorite status

set -e

path="$1"
action="$2"
favorites="$HOME/.local/share/wallpaper-favorites"
mkdir -p "$(dirname "$favorites")"
touch "$favorites"

if [ "$action" = "add" ]; then
	grep -qxF "$path" "$favorites" || echo "$path" >>"$favorites"
else
	grep -vxF "$path" "$favorites" >"$favorites.tmp" || true
	mv "$favorites.tmp" "$favorites"
fi
