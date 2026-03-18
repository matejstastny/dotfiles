#!/bin/bash

source "$CONFIG_DIR/colors.sh"

SID="$1"
FOCUSED=$(aerospace list-workspaces --focused)

APPS=$(aerospace list-windows --workspace "$SID" 2>/dev/null | awk -F '|' '{gsub(/^ *| *$/, "", $2); print $2}')
ICON_LIST=""

if [ -n "$APPS" ]; then
    while IFS= read -r app; do
        [ -z "$app" ] && continue
        icon=$("$CONFIG_DIR/plugins/icon_map_fn.sh" "$app")
        ICON_LIST="${ICON_LIST}${ICON_LIST:+ }${icon}"
    done <<< "$APPS"
fi

if [ "$SID" = "$FOCUSED" ]; then
    sketchybar --set "space.$SID" \
        icon.color=$FG_PRIMARY \
        label="${ICON_LIST:- }" \
        label.color=$FG_PRIMARY \
        background.drawing=on \
        background.color=$BG_HIGHLIGHT
elif [ -n "$ICON_LIST" ]; then
    sketchybar --set "space.$SID" \
        icon.color=$FG_SECONDARY \
        label="$ICON_LIST" \
        label.color=$FG_MUTED \
        background.drawing=off
else
    sketchybar --set "space.$SID" \
        icon.color=$FG_MUTED \
        label="" \
        background.drawing=off
fi
