#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

sketchybar --add item workspace left \
  --set workspace \
    icon.font="JetBrainsMono Nerd Font Mono:Bold:13.0" \
    icon.color="$COLOR_MAUVE" \
    icon.padding_left=10 \
    icon.padding_right=6 \
    label.font="$FONT_TEXT" \
    label.color="$COLOR_SUBTEXT" \
    label.padding_right=10 \
    update_freq=0 \
    script="$PLUGIN_DIR/workspace.sh" \
  --subscribe workspace space_change window_focus

sketchybar --add bracket workspace_bracket workspace \
  --set workspace_bracket \
    background.color="$COLOR_SURFACE" \
    background.corner_radius=10 \
    background.height=30 \
    background.drawing=on
