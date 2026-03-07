#!/bin/bash

source "$CONFIG_DIR/colors.sh"

INDEX=0
ALL_WORKSPACES=$(aerospace list-workspaces --all)

for sid in $ALL_WORKSPACES; do
    sketchybar --add item space.$sid left \
        --subscribe space.$sid aerospace_workspace_change front_app_switched \
        --set space.$sid \
        background.color=$SUMI_INK4 \
        background.corner_radius=5 \
        background.height=20 \
        background.drawing=off \
        icon.padding_left=0 \
        icon.padding_right=0 \
        label.padding_left=3 \
        label.padding_right=3 \
        label.color=$OLD_WHITE \
        label.font="sketchybar-app-font:Regular:16.0" \
        click_script="aerospace workspace $sid" \
        script="$CONFIG_DIR/plugins/aerospace.sh $sid"

    if [[ $sid != $(echo "$ALL_WORKSPACES" | tail -n1) ]]; then
        sketchybar --add item space_separator.$sid left \
            --set space_separator.$sid \
            icon="" \
            icon.color=$FUJI_GRAY \
            icon.padding_left=8 \
            icon.font="DankMono Nerd Font Mono:Regular:20.0" \
            label.drawing=off
    fi

    INDEX=$((INDEX + 1))
done
