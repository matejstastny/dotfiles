#!/bin/bash

sketchybar --add item battery right \
    --set battery \
        icon.color=$FG_MUTED \
        update_freq=120 \
        script="$PLUGIN_DIR/battery.sh" \
    --subscribe battery system_woke power_source_change
