#!/usr/bin/env bash
chosen=$(printf "󰌾 Lock\n󰒲 Suspend\n󰜉 Reboot\n󰐥 Shutdown" \
    | rofi -dmenu -p "✦ system ✦" \
        -theme-str 'window { width: 220px; } listview { lines: 4; }')

case "$chosen" in
    *Lock)     hyprlock ;;
    *Suspend)  systemctl suspend ;;
    *Reboot)   systemctl reboot ;;
    *Shutdown) systemctl poweroff ;;
esac
