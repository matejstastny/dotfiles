#!/bin/bash

source "$CONFIG_DIR/icons.sh"

if [ "$SENDER" = "volume_change" ]; then
    VOLUME="$INFO"
else
    VOLUME=$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)
fi

case "$VOLUME" in
    [6-9][0-9]|100) ICON=$ICON_VOL_HIGH ;;
    [3-5][0-9])     ICON=$ICON_VOL_MED ;;
    [1-9]|[1-2][0-9]) ICON=$ICON_VOL_LOW ;;
    *)              ICON=$ICON_VOL_MUTE ;;
esac

sketchybar --set "$NAME" icon="$ICON" label="${VOLUME}%"
