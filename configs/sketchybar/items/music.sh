#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

sketchybar --add item music left \
  --set music \
    icon="󰄛" \
    icon.font="$FONT_ICON" \
    icon.color="$COLOR_PINK" \
    icon.padding_left=8 \
    icon.padding_right=6 \
    label.color="$COLOR_SUBTEXT" \
    label.padding_right=10 \
    update_freq=5 \
    script="$PLUGIN_DIR/music.sh" \
  --subscribe music media_change mouse.clicked

sketchybar --add bracket music_bracket music \
  --set music_bracket \
    background.color="$COLOR_SURFACE" \
    background.corner_radius=10 \
    background.height=30 \
    background.drawing=on
