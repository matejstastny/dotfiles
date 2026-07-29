#!/usr/bin/env bash
# obsidian

NOTES_DIR="$HOME/notes"
INBOX="$NOTES_DIR/inbox.md"

mkdir -p "$NOTES_DIR"
[ -f "$INBOX" ] || touch "$INBOX"

text=$(rofi -dmenu -l 0 -p "✦ capture ✦")
[ -z "$text" ] && exit 0

printf -- '- %s %s\n' "$(date '+%Y-%m-%d %H:%M')" "$text" >>"$INBOX"
notify-send -t 2000 "✦ capture" "→ inbox.md" 2>/dev/null
