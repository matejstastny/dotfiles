#!/bin/bash

source "$CONFIG_DIR/colors.sh"

WORKSPACES=$(aerospace list-workspaces --all)

for sid in $WORKSPACES; do
    sketchybar --add item space.$sid left \
        --set space.$sid \
            icon="$sid" \
            icon.font="SF Pro:Bold:13.0" \
            icon.color=$FG_MUTED \
            icon.padding_left=8 \
            icon.padding_right=2 \
            label.font="sketchybar-app-font:Regular:14.0" \
            label.color=$FG_MUTED \
            label.padding_left=2 \
            label.padding_right=8 \
            label.y_offset=1 \
            background.color=$BG_HIGHLIGHT \
            background.corner_radius=8 \
            background.height=26 \
            background.drawing=off \
            padding_left=2 \
            padding_right=2 \
            click_script="aerospace workspace $sid" \
            script="$PLUGIN_DIR/aerospace.sh $sid" \
        --subscribe space.$sid aerospace_workspace_change front_app_switched
done

# Shared background for all workspaces
BRACKET_MEMBERS=""
for sid in $WORKSPACES; do
    BRACKET_MEMBERS="$BRACKET_MEMBERS space.$sid"
done
sketchybar --add bracket workspaces $BRACKET_MEMBERS \
    --set workspaces \
        background.color=$BG_SECONDARY \
        background.corner_radius=8 \
        background.height=28 \
        background.drawing=on
