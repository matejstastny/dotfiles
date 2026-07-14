#!/usr/bin/env bash
# Fuzzy-pick a note and open it in Obsidian.
# reqs: rofi, rg, python3, obsidian (bin/obsidian)

NOTES_DIR="$HOME/notes"
VAULT_ID="aa847f942e019397" # from ~/.config/obsidian/obsidian.json

sel=$( (cd "$NOTES_DIR" && rg --files -g '*.md' 2>/dev/null | sort) |
	rofi -dmenu -i -p "✦ notes ✦")
[ -z "$sel" ] && exit 0

rel="${sel%.md}"
enc=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$rel")

"$HOME/dotfiles/bin/obsidian" "obsidian://open?vault=$VAULT_ID&file=$enc" >/dev/null 2>&1 &
