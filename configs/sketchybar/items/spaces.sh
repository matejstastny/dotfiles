#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

for i in $(seq 1 9); do
  sketchybar --add item "space.$i" left \
    --set "space.$i" \
      icon="●" \
      icon.font="$FONT_ICON" \
      icon.color="$COLOR_MUTED" \
      icon.padding_left=5 \
      icon.padding_right=5 \
      label.drawing=off \
      background.drawing=off \
      padding_left=1 \
      padding_right=1 \
      click_script="yabai -m space --focus $i 2>/dev/null" \
      update_freq=0 \
      script="$PLUGIN_DIR/spaces.sh $i" \
    --subscribe "space.$i" space_change mouse.clicked
done

sketchybar --add bracket spaces_bracket \
    space.1 space.2 space.3 space.4 space.5 \
    space.6 space.7 space.8 space.9 \
  --set spaces_bracket \
    background.color="$COLOR_SURFACE" \
    background.corner_radius=10 \
    background.height=30 \
    background.drawing=on \
    padding_left=2 \
    padding_right=2
