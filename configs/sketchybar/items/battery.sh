#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

sketchybar --add item battery right \
  --set battery \
    icon.font="$FONT_ICON" \
    icon.color="$COLOR_GREEN" \
    label.font="$FONT_TEXT" \
    label.color="$COLOR_TEXT" \
    update_freq=60 \
    script="$PLUGIN_DIR/battery.sh"
