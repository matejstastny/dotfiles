#!/usr/bin/env bash
#@ record a launched app id in the quickshell launcher's MRU history
history_file="$HOME/.local/share/quickshell-launcher-mru"
mkdir -p "$(dirname "$history_file")"
touch "$history_file"

id="$1"
[ -z "$id" ] && exit 0

tmp=$(mktemp)
echo "$id" >"$tmp"
grep -Fxv "$id" "$history_file" | head -199 >>"$tmp"
mv "$tmp" "$history_file"
