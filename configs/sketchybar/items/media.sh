#!/bin/bash

source "$CONFIG_DIR/colors.sh"

sketchybar --add item media center \
    --set media \
    icon=󰝚 \
    icon.color=$ONI_VIOLET \
    label.max_chars=30 \
    label.color=$OLD_WHITE \
    update_freq=5 \
    script="$PLUGIN_DIR/media.sh"
