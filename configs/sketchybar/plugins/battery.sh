#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

LEVEL=$(pmset -g batt | grep -Eo '[0-9]+%' | head -1 | tr -d '%')
CHARGING=$(pmset -g batt | grep -c 'AC Power' || true)

if [ "$CHARGING" -gt 0 ]; then
  ICON="󰂄"; COLOR="$COLOR_GREEN"
elif [ "${LEVEL:-100}" -lt 15 ]; then
  ICON="󰂎"; COLOR="$COLOR_MAROON"
elif [ "${LEVEL:-100}" -lt 40 ]; then
  ICON="󰁺"; COLOR="$COLOR_YELLOW"
elif [ "${LEVEL:-100}" -lt 60 ]; then
  ICON="󰁼"; COLOR="$COLOR_SUBTEXT"
elif [ "${LEVEL:-100}" -lt 80 ]; then
  ICON="󰁿"; COLOR="$COLOR_SUBTEXT"
else
  ICON="󰂂"; COLOR="$COLOR_GREEN"
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${LEVEL}%"
