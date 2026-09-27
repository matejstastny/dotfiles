#!/usr/bin/env bash
#@ copy the latest Quick Share image to the clipboard again

set -euo pipefail

STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/quickshare/status.json"

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

if "$HOME/dotfiles/scripts/quickshare-own.sh" "$file"; then
	notify-send -t 3000 "✦ quick share" "Copied $(basename "$file") to clipboard"
else
	notify-send -u critical -t 6000 "✦ quick share" "Clipboard copy failed"
	exit 1
fi
