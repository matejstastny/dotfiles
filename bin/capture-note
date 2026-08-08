#!/usr/bin/env bash
#@ append a timestamped line to the inbox, used by the quickshell capture picker
NOTES_DIR="$HOME/notes"
INBOX="$NOTES_DIR/inbox.md"

text="$1"
[ -z "$text" ] && exit 0

mkdir -p "$NOTES_DIR"
[ -f "$INBOX" ] || touch "$INBOX"

printf -- '- %s %s\n' "$(date '+%Y-%m-%d %H:%M')" "$text" >>"$INBOX"
notify-send -t 2000 "✦ capture" "→ inbox.md" 2>/dev/null
