#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

sketchybar --add item cpu right \
  --set cpu \
    icon="󰻠" \
    icon.font="$FONT_ICON" \
    icon.color="$COLOR_PURPLE" \
    label.font="$FONT_TEXT" \
    label.color="$COLOR_TEXT" \
    update_freq=5 \
    script="$PLUGIN_DIR/cpu.sh"
