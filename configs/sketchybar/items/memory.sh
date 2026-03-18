#!/bin/bash

source "$CONFIG_DIR/icons.sh"

sketchybar --add item memory right \
    --set memory \
        icon="$ICON_MEM" \
        icon.color=$FG_MUTED \
        label="–" \
        update_freq=10 \
        script="$PLUGIN_DIR/memory.sh"
