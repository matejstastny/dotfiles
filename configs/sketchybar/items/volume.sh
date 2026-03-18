#!/bin/bash

source "$CONFIG_DIR/icons.sh"

sketchybar --add item volume right \
    --set volume \
        icon="$ICON_VOL_HIGH" \
        icon.color=$FG_MUTED \
        icon.padding_right=4 \
        script="$PLUGIN_DIR/volume.sh" \
    --subscribe volume volume_change
