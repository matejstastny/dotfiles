#!/usr/bin/env bash
#@ screenshot region

DIR="$HOME/pictures/screenshots"
mkdir -p "$DIR"
FILE="$DIR/$(date +%Y%m%d_%H%M%S).png"

FILE=$(mktemp /tmp/screenshot-XXXX.png)
grim -g "$(slurp)" "$FILE" && wl-copy --type image/png <"$FILE" &&
	notify-send "✦ screenshot" "Region saved & copied to clipboard" -t 2000
