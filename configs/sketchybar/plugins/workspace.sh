#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

SPACES=$(yabai -m query --spaces 2>/dev/null) || exit 0
WINDOWS=$(yabai -m query --windows 2>/dev/null)

SPACE_IDX=$(echo "$SPACES" | jq -r '.[] | select(."has-focus" == true) | .index')
APP=$(echo "$WINDOWS" | jq -r '.[] | select(."has-focus" == true) | .app' 2>/dev/null | head -1)

ICON="${SPACE_IDX:-?}"
LABEL="${APP:-Desktop}"

sketchybar --set "$NAME" icon="$ICON" label="· $LABEL"
