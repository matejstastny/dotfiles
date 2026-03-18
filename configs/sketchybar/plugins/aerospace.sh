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
    if [ -n "$ICON_LIST" ]; then
        sketchybar --set "space.$SID" \
            icon="$ICON_LIST" \
            icon.font="sketchybar-app-font:Regular:14.0" \
            icon.color=$FG_PRIMARY \
            icon.padding_left=8 \
            icon.padding_right=8 \
            background.drawing=on \
            background.color=$BG_HIGHLIGHT
    else
        sketchybar --set "space.$SID" \
            icon="●" \
            icon.font="DankMono Nerd Font Mono:Regular:18.0" \
            icon.color=$FG_PRIMARY \
            icon.padding_left=6 \
            icon.padding_right=6 \
            background.drawing=on \
            background.color=$BG_HIGHLIGHT
    fi
elif [ -n "$ICON_LIST" ]; then
    sketchybar --set "space.$SID" \
        icon="$ICON_LIST" \
        icon.font="sketchybar-app-font:Regular:14.0" \
        icon.color=$FG_MUTED \
        icon.padding_left=8 \
        icon.padding_right=8 \
        background.drawing=off
else
    sketchybar --set "space.$SID" \
        icon="●" \
        icon.font="DankMono Nerd Font Mono:Regular:15.0" \
        icon.color=$FG_MUTED \
        icon.padding_left=6 \
        icon.padding_right=6 \
        background.drawing=off
fi
