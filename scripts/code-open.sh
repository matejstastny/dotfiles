#!/usr/bin/env bash
#@ open a vscode project (MRU-reorder history) via the quickshell code picker
history_file="$HOME/.local/share/vscode-projects"
mkdir -p "$(dirname "$history_file")"
touch "$history_file"

abs="$1"
devcontainer=0
[ "$2" = "--devcontainer" ] && devcontainer=1
[ -z "$abs" ] && exit 1

tmp=$(mktemp)
echo "$abs" >"$tmp"
grep -Fxv "$abs" "$history_file" | head -49 >>"$tmp"
mv "$tmp" "$history_file"

if [ "$devcontainer" = 1 ]; then
	kitty devcon "$abs" &
else
	code "$abs"
fi
