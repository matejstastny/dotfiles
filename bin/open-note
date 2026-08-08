#!/usr/bin/env bash
#@ open a note in obsidian by vault-relative path, used by the quickshell notes picker
VAULT_ID="aa847f942e019397" # from ~/.config/obsidian/obsidian.json

sel="$1"
[ -z "$sel" ] && exit 1

rel="${sel%.md}"
enc=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$rel")

"$HOME/dotfiles/bin/obsidian" "obsidian://open?vault=$VAULT_ID&file=$enc" >/dev/null 2>&1 &
