#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

sketchybar --add item volume right \
  --set volume \
    icon.font="$FONT_ICON" \
    icon.color="$COLOR_TEAL" \
    label.font="$FONT_TEXT" \
    label.color="$COLOR_TEXT" \
    label.padding_right=10 \
    update_freq=0 \
    script="$PLUGIN_DIR/volume.sh" \
  --subscribe volume volume_change mouse.clicked \
  --add bracket volume_bracket volume \
  --set volume_bracket \
    background.color="$COLOR_SURFACE" \
    background.corner_radius=10 \
    background.height=30 \
    background.drawing=on
