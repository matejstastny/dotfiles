#!/usr/bin/env bash

RUNNING=$(osascript -e 'if application "Music" is running then return 0')
if [ "$RUNNING" == "" ]; then
    RUNNING=1
fi

PLAYING=1
TRACK=""
ALBUM=""
ARTIST=""

if [ "$(osascript -e 'if application "Music" is running then tell application "Music" to get player state')" == "playing" ]; then
    PLAYING=0
    TRACK=$(osascript -e 'tell application "Music" to get name of current track')
    ARTIST=$(osascript -e 'tell application "Music" to get artist of current track')
    ALBUM=$(osascript -e 'tell application "Music" to get album of current track')
    MAX_LEN=40
    LABEL=""
fi

if [ $RUNNING -eq 0 ] && [ $PLAYING -eq 0 ]; then
    if [ "$ARTIST" == "" ]; then
        LABEL="$TRACK - $ALBUM"
    else
        LABEL="$TRACK - $ARTIST"
    fi

    # Truncate label if too long (prevents notch overlap)
    if [ ${#LABEL} -gt $MAX_LEN ]; then
        LABEL="${LABEL:0:$((MAX_LEN - 1))}…"
    fi

    sketchybar -m --set "$NAME" drawing=on
    sketchybar -m --set "$NAME" label="$LABEL"
else
    sketchybar -m --set "$NAME" drawing=off
    sketchybar -m --set "$NAME" label=""
fi
