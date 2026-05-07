#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

if ! command -v nowplaying-cli &>/dev/null; then
  sketchybar --set "$NAME" label="install nowplaying-cli~" icon.color="$COLOR_MUTED"
  exit 0
fi

TITLE=$(nowplaying-cli get title 2>/dev/null)
ARTIST=$(nowplaying-cli get artist 2>/dev/null)
RATE=$(nowplaying-cli get playbackRate 2>/dev/null)

if [ -z "$TITLE" ] || [ "$TITLE" = "null" ] || [ "$RATE" = "0" ] || [ "$RATE" = "null" ]; then
  sketchybar --set "$NAME" label="nothing playing~" icon.color="$COLOR_MUTED"
  exit 0
fi

MAX=50
if [ -n "$ARTIST" ] && [ "$ARTIST" != "null" ]; then
  DISPLAY="$TITLE — $ARTIST"
else
  DISPLAY="$TITLE"
fi

if [ ${#DISPLAY} -gt $MAX ]; then
  DISPLAY="${DISPLAY:0:$MAX}…"
fi

sketchybar --set "$NAME" label="$DISPLAY" icon.color="$COLOR_PINK"
