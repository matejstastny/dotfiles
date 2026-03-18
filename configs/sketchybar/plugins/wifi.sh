#!/bin/bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

WIFI_IF=$(networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi/{getline; print $2}')
SSID=$(networksetup -getairportnetwork "${WIFI_IF:-en0}" 2>/dev/null | awk -F': ' '/Current Wi-Fi Network/{print $2}')

if [ -z "$SSID" ]; then
    sketchybar --set "$NAME" icon="$ICON_WIFI_OFF" label="Off"
else
    sketchybar --set "$NAME" icon="$ICON_WIFI" label="$SSID"
fi
