#!/usr/bin/env bash
chosen=$(printf "󰌾 Lock\n󰒲 Suspend\n󰍃 Logout\n󰜉 Reboot\n󰐥 Shutdown" |
	rofi -dmenu -p "✦ system ✦" \
		-theme-str 'window { width: 220px; } listview { lines: 5; }')

case "$chosen" in
*Lock) hyprlock ;;
*Suspend) systemctl suspend ;;
*Logout) pkill -x Hyprland ;;
*Reboot) systemctl reboot ;;
*Shutdown) systemctl poweroff ;;
esac
