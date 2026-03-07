#!/bin/bash

WEATHER=$(curl -s "wttr.in?format=%c%t" 2>/dev/null | sed 's/+//')

if [[ -z "$WEATHER" ]] || [[ "$WEATHER" == *"Unknown"* ]]; then
    sketchybar --set "$NAME" label="N/A"
else
    sketchybar --set "$NAME" label="$WEATHER"
fi
