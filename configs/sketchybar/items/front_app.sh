#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

sketchybar --add item front_app left \
  --set front_app \
    icon="󰣨" \
    icon.font="$FONT_ICON" \
    icon.color="$COLOR_BLUE" \
    icon.padding_left=10 \
    label.font="$FONT_TEXT" \
    label.color="$COLOR_TEXT" \
    label.padding_right=10 \
    background.color="$COLOR_SURFACE" \
    background.corner_radius=10 \
    background.height=30 \
    background.drawing=on \
    padding_left=4 \
    padding_right=4 \
    script="$PLUGIN_DIR/front_app.sh" \
  --subscribe front_app front_app_switched window_focus
