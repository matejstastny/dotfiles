#!/usr/bin/env bash

REC_DIR="$HOME/pictures/screenrecord"

sel=$(ls -t "$REC_DIR" 2>/dev/null |
	rofi -dmenu -i -p "✦ recordings ✦")
[ -z "$sel" ] && exit 0

mpv "$REC_DIR/$sel" &
