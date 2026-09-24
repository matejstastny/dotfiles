#!/usr/bin/env bash
#@ screenshot full screen

DIR="$HOME/pictures/screenshots"
mkdir -p "$DIR"
FILE="$DIR/$(date +%Y%m%d_%H%M%S).png"

grim "$FILE" && wl-copy --type image/png <"$FILE" &&
	notify-send "✦ screenshot" "Saved & copied to clipboard" -t 2000
