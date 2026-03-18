#!/bin/bash

source "$CONFIG_DIR/icons.sh"

sketchybar --add item cpu right \
    --set cpu \
        icon="$ICON_CPU" \
        icon.color=$FG_MUTED \
        label="–" \
        update_freq=4 \
        script="$PLUGIN_DIR/cpu.sh"
