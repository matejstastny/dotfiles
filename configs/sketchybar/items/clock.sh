#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

sketchybar --add item clock right \
  --set clock \
    icon="󰃭" \
    icon.font="$FONT_ICON" \
    icon.color="$COLOR_PINK" \
    label.color="$COLOR_TEXT" \
    label.padding_right=10 \
    update_freq=20 \
    script="$PLUGIN_DIR/clock.sh" \
  --add bracket time_bracket clock \
  --set time_bracket \
    background.color="$COLOR_SURFACE" \
    background.corner_radius=10 \
    background.height=30 \
    background.drawing=on
