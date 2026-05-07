#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

sketchybar --add item disk right \
  --set disk \
    icon="󰋊" \
    icon.font="$FONT_ICON" \
    icon.color="$COLOR_PEACH" \
    label.color="$COLOR_TEXT" \
    label.padding_right=10 \
    update_freq=120 \
    script="$PLUGIN_DIR/disk.sh" \
  --add bracket disk_bracket disk \
  --set disk_bracket \
    background.color="$COLOR_SURFACE" \
    background.corner_radius=10 \
    background.height=30 \
    background.drawing=on
