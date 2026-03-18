#!/bin/bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

SSID=$(/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I 2>/dev/null | awk -F': ' '/^ *SSID/{print $2}')

if [ -z "$SSID" ]; then
    sketchybar --set "$NAME" icon="$ICON_WIFI_OFF" label="Off"
else
    sketchybar --set "$NAME" icon="$ICON_WIFI" label="$SSID"
fi
