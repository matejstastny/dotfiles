#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

sketchybar --add item memory right \
  --set memory \
    icon="󰍛" \
    icon.font="$FONT_ICON" \
    icon.color="$COLOR_BLUE" \
    label.font="$FONT_TEXT" \
    label.color="$COLOR_TEXT" \
    update_freq=15 \
    script="$PLUGIN_DIR/memory.sh" \
  --add bracket stats_bracket cpu memory \
  --set stats_bracket \
    background.color="$COLOR_SURFACE" \
    background.corner_radius=10 \
    background.height=30 \
    background.drawing=on
