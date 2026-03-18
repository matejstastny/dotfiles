#!/bin/bash

source "$CONFIG_DIR/icons.sh"

sketchybar --add item wifi right \
    --set wifi \
        icon="$ICON_WIFI" \
        icon.color=$FG_MUTED \
        update_freq=10 \
        script="$PLUGIN_DIR/wifi.sh" \
    --subscribe wifi system_woke
