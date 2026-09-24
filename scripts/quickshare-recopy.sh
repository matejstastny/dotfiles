#!/usr/bin/env bash
#@ copy the latest Quick Share image to the clipboard again

set -euo pipefail

STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/quickshare/status.json"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/quickshare"

if [ ! -f "$STATE_FILE" ]; then
	notify-send -t 3000 "✦ quick share" "No received image yet"
	exit 1
fi

file=$(jq -r '.file // empty' "$STATE_FILE")
format=$(jq -r '.format // empty' "$STATE_FILE")
if [ -z "$file" ] || [ -z "$format" ] || [ ! -f "$file" ]; then
	notify-send -t 3000 "✦ quick share" "Last image is no longer available"
	exit 1
fi

owner_pid_file="$STATE_DIR/clipboard-owner.pid"
if [ -f "$owner_pid_file" ]; then
	owner_pid=$(<"$owner_pid_file")
	if kill -0 "$owner_pid" 2>/dev/null; then
		kill "$owner_pid"
	fi
fi
magick "$file" png:- | "$HOME/dotfiles/scripts/quickshare-clipboard-owner.py" "$file" "$owner_pid_file" &
notify-send -t 3000 "✦ quick share" "Copied $(basename "$file") to clipboard"
