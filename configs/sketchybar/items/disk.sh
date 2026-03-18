#!/bin/bash

source "$CONFIG_DIR/icons.sh"

sketchybar --add item disk right \
    --set disk \
        icon="$ICON_DISK" \
        icon.color=$FG_MUTED \
        label="–" \
        update_freq=60 \
        script="$PLUGIN_DIR/disk.sh"
