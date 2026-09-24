#!/usr/bin/env bash
#@ report Quick Share state for the bar

set -euo pipefail

STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/quickshare/status.json"
receiver=$(systemctl is-active quickshare-taildrop.service 2>/dev/null || true)
watcher=$(systemctl --user is-active quickshare-clipboard.service 2>/dev/null || true)

if [ -f "$STATE_FILE" ]; then
	file=$(jq -r '.file // empty' "$STATE_FILE")
	received=$(jq -r '.received // empty' "$STATE_FILE")
	if [ -n "$file" ] && [ -f "$file" ]; then
		jq -cn \
			--arg file "$(basename "$file")" \
			--arg received "$received" \
			--arg receiver "$receiver" \
			--arg watcher "$watcher" \
			'{text: "󰉍", title: "quick share", headline: $file, lines: [("received " + $received), "click to copy again", ("receiver " + $receiver + " · clipboard " + $watcher)], class: "running"}'
		exit
	fi
fi

if [ "$receiver" = "active" ] && [ "$watcher" = "active" ]; then
	printf '{"text":"󰉍","title":"quick share","headline":"ready","lines":["incoming images go to ~/quickshare","click copies the last image","waiting for a Taildrop"],"class":"running"}\n'
else
	jq -cn --arg receiver "$receiver" --arg watcher "$watcher" \
		'{text: "󰉍", title: "quick share", headline: "unavailable", lines: [("receiver " + $receiver + " · clipboard " + $watcher)], class: "offline"}'
fi
