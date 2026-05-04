#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

SPACE_INDEX="$1"
SPACES=$(yabai -m query --spaces 2>/dev/null) || exit 0

FOCUSED=$(echo "$SPACES" | jq -r '.[] | select(."has-focus" == true) | .index')
VISIBLE=$(echo "$SPACES" | jq -r ".[] | select(.index == $SPACE_INDEX) | .\"is-visible\"")
WIN_COUNT=$(echo "$SPACES" | jq -r ".[] | select(.index == $SPACE_INDEX) | .windows | length")

if [ "$FOCUSED" = "$SPACE_INDEX" ]; then
  sketchybar --set "$NAME" icon.color="$COLOR_BLUE"
elif [ "${WIN_COUNT:-0}" -gt 0 ]; then
  sketchybar --set "$NAME" icon.color="$COLOR_TEXT"
else
  sketchybar --set "$NAME" icon.color="$COLOR_MUTED"
fi
