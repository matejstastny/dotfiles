#!/usr/bin/env bash
#@ remove a project from the vscode picker's MRU history
history_file="$HOME/.local/share/vscode-projects"
[ -f "$history_file" ] || exit 0

abs="$1"
[ -z "$abs" ] && exit 1

tmp=$(mktemp)
grep -Fxv "$abs" "$history_file" >"$tmp"
mv "$tmp" "$history_file"
