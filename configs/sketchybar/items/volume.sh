#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

sketchybar --add item volume right \
  --set volume \
    icon.font="$FONT_ICON" \
    icon.color="$COLOR_CYAN" \
    label.font="$FONT_TEXT" \
    label.color="$COLOR_TEXT" \
    update_freq=0 \
    script="$PLUGIN_DIR/volume.sh" \
  --subscribe volume volume_change mouse.clicked

sketchybar --add bracket controls_bracket volume battery \
  --set controls_bracket \
    background.color="$COLOR_SURFACE" \
    background.corner_radius=10 \
    background.height=30 \
    background.drawing=on
