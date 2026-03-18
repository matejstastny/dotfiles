#!/bin/bash

sketchybar --add item clock right \
    --set clock \
        icon.drawing=off \
        label.font="SF Pro:Semibold:13.0" \
        label.color=$FG_PRIMARY \
        label.padding_left=10 \
        label.padding_right=10 \
        update_freq=30 \
        script="$PLUGIN_DIR/clock.sh"
