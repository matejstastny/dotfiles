#!/bin/bash
#@ hyprland system reload

set -e

if ! output=$(hyprctl reload 2>&1); then
	notify-send -u critical "✦ hr" "Reload failed: $output"
	exit 1
fi

errors=$(hyprctl configerrors)
if [ -n "$errors" ]; then
	notify-send -u critical "✦ hr" "Config error: $errors"
	exit 1
fi

pkill -x quickshell 2>/dev/null || true
pkill -x qs 2>/dev/null || true

for _ in {1..20}; do
	if ! pgrep -x quickshell >/dev/null && ! pgrep -x qs >/dev/null; then
		break
	fi
	sleep 0.1
done

if pgrep -x quickshell >/dev/null || pgrep -x qs >/dev/null; then
	notify-send -u critical "✦ hr" "Quickshell did not stop"
	exit 1
fi

setsid env QT_QPA_PLATFORMTHEME=gtk3 qs >/dev/null 2>&1 < /dev/null &
sleep 0.5

if ! pgrep -x quickshell >/dev/null && ! pgrep -x qs >/dev/null; then
	notify-send -u critical "✦ hr" "Quickshell did not start"
	exit 1
fi

notify-send -t 2000 "✦ hr" "hyprland reloaded"
