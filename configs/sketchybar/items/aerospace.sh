#!/bin/bash

source "$CONFIG_DIR/colors.sh"

WORKSPACES=$(aerospace list-workspaces --all)

for sid in $WORKSPACES; do
    sketchybar --add item space.$sid left \
        --set space.$sid \
            icon="●" \
            icon.font="DankMono Nerd Font Mono:Regular:18.0" \
            icon.color=$FG_MUTED \
            icon.padding_left=6 \
            icon.padding_right=6 \
            label.drawing=off \
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
