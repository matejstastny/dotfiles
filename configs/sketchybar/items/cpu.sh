#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

NCPU=$(sysctl -n hw.logicalcpu)

for i in $(seq 0 $((NCPU - 1))); do
  sketchybar --add item "cpu.$i" right \
    --set "cpu.$i" \
      icon.drawing=off \
      label.font="JetBrainsMono Nerd Font Mono:Bold:15.0" \
      label.color="$COLOR_MUTED" \
      label.padding_left=1 \
      label.padding_right=1 \
      label="▁" \
      background.drawing=off \
      width=14 \
      update_freq=0 \
      script=""
done

# Hidden driver — runs every 2s, updates all bars
sketchybar --add item cpu_driver right \
  --set cpu_driver \
    update_freq=2 \
    script="$PLUGIN_DIR/cpu.sh" \
    icon.drawing=off \
    label.drawing=off \
    background.color="$COLOR_TRANSPARENT" \
    background.height=0 \
    width=0

BRACKET_ITEMS="cpu_driver"
for i in $(seq 0 $((NCPU - 1))); do
  BRACKET_ITEMS="$BRACKET_ITEMS cpu.$i"
done

# shellcheck disable=SC2086
sketchybar --add bracket cpu_bracket $BRACKET_ITEMS \
  --set cpu_bracket \
    background.color="$COLOR_SURFACE" \
    background.corner_radius=10 \
    background.height=30 \
    background.drawing=on
