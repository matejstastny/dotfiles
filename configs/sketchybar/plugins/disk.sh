#!/usr/bin/env bash
# Use Data volume for meaningful user-visible usage; fall back to /
VOLUME="/System/Volumes/Data"
[ -d "$VOLUME" ] || VOLUME="/"

read -r USED TOTAL <<< "$(df "$VOLUME" | awk 'NR==2 {
  printf "%dG %dG", int($3*512/1073741824), int($2*512/1073741824)
}')"

sketchybar --set "$NAME" label="$USED / $TOTAL"
