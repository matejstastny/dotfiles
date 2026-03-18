#!/bin/bash

sketchybar --add item front_app left \
    --set front_app \
        icon.font="sketchybar-app-font:Regular:16.0" \
        icon.color=$FG_SECONDARY \
        icon.padding_left=12 \
        label.font="SF Pro:Semibold:13.0" \
        label.color=$FG_SECONDARY \
        label.padding_left=4 \
        script="$PLUGIN_DIR/front_app.sh" \
    --subscribe front_app front_app_switched
