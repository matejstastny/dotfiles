#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

sketchybar --add item memory right \
  --set memory \
    icon="󰍛" \
    icon.font="$FONT_ICON" \
    icon.color="$COLOR_LAVENDER" \
    label.color="$COLOR_TEXT" \
    label.padding_right=10 \
    update_freq=15 \
    script="$PLUGIN_DIR/memory.sh" \
  --add bracket memory_bracket memory \
  --set memory_bracket \
    background.color="$COLOR_SURFACE" \
    background.corner_radius=10 \
    background.height=30 \
    background.drawing=on
