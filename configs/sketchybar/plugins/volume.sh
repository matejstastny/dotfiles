#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

VOLUME=$(osascript -e 'output volume of (get volume settings)' 2>/dev/null || echo 0)
MUTED=$(osascript -e 'output muted of (get volume settings)' 2>/dev/null || echo false)

if [ "$MUTED" = "true" ]; then
  ICON="󰝟"; COLOR="$COLOR_MUTED"
elif [ "$VOLUME" -lt 30 ]; then
  ICON="󰕿"; COLOR="$COLOR_CYAN"
elif [ "$VOLUME" -lt 70 ]; then
  ICON="󰖀"; COLOR="$COLOR_CYAN"
else
  ICON="󰕾"; COLOR="$COLOR_CYAN"
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${VOLUME}%"
