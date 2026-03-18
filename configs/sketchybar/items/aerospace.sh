#!/bin/bash

source "$CONFIG_DIR/colors.sh"

INDEX=0
ALL_WORKSPACES=$(aerospace list-workspaces --all)

for sid in $ALL_WORKSPACES; do
    sketchybar --add item space.$sid left \
        --subscribe space.$sid aerospace_workspace_change front_app_switched \
        --set space.$sid \
        background.color=$BG_HIGHLIGHT \
        background.corner_radius=4 \
        background.height=20 \
        background.drawing=off \
        icon.padding_left=0 \
        icon.padding_right=0 \
        label.padding_left=6 \
        label.padding_right=6 \
        label.color=$FG_SECONDARY \
        label.font="sketchybar-app-font:Regular:14.0" \
        click_script="aerospace workspace $sid" \
        script="$CONFIG_DIR/plugins/aerospace.sh $sid"

    INDEX=$((INDEX + 1))
done
