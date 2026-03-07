#!/bin/bash

TITLE=$(nowplaying-cli get title 2>/dev/null)
ARTIST=$(nowplaying-cli get artist 2>/dev/null)

if [[ "$TITLE" == "null" ]] || [[ -z "$TITLE" ]]; then
    sketchybar --set "$NAME" drawing=off
else
    sketchybar --set "$NAME" drawing=on label="$ARTIST - $TITLE"
fi
