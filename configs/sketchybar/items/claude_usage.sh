#!/bin/bash

sketchybar --add item claude_usage right \
    --set claude_usage \
        icon="󱙺" \
        icon.color=$PURPLE \
        label="..." \
        update_freq=60 \
        script="$PLUGIN_DIR/claude_usage.sh"
