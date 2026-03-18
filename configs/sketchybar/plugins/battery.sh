#!/bin/bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

BATTERY_INFO=$(pmset -g batt)
PERCENTAGE=$(echo "$BATTERY_INFO" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')
CHARGING=$(echo "$BATTERY_INFO" | grep -c 'AC Power')

if [ -z "$PERCENTAGE" ]; then
    sketchybar --set "$NAME" icon.drawing=off label.drawing=off
    exit 0
fi

case "$PERCENTAGE" in
    [0-9]|1[0-9])    ICON=$ICON_BAT_0;   COLOR=$RED ;;
    [2-3][0-9])       ICON=$ICON_BAT_25;  COLOR=$YELLOW ;;
    [4-5][0-9])       ICON=$ICON_BAT_50;  COLOR=$FG_MUTED ;;
    [6-7][0-9])       ICON=$ICON_BAT_75;  COLOR=$FG_MUTED ;;
    *)                ICON=$ICON_BAT_100;  COLOR=$FG_MUTED ;;
esac

if [ "$CHARGING" -gt 0 ]; then
    ICON=$ICON_BAT_CHARGING
    COLOR=$GREEN
fi

sketchybar --set "$NAME" \
    icon="$ICON" \
    icon.color="$COLOR" \
    label="${PERCENTAGE}%"
