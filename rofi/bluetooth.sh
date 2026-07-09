#!/usr/bin/env bash
# bluetooth connect/disconnect via rofi

is_connected() { bluetoothctl info "$1" 2>/dev/null | grep -q "Connected: yes"; }

list_devices() {
	bluetoothctl devices 2>/dev/null | while read -r _ mac name; do
		[ -z "$mac" ] && continue
		if is_connected "$mac"; then
			printf '󰂱  %s  ·  %s\n' "$name" "$mac"
		else
			printf '󰂯  %s  ·  %s\n' "$name" "$mac"
		fi
	done
}

choice=$(list_devices | rofi -dmenu -i -p "✦ bluetooth ✦")
[ -z "$choice" ] && exit 0

mac=$(echo "$choice" | grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}')
[ -z "$mac" ] && exit 0

if is_connected "$mac"; then
	bluetoothctl disconnect "$mac"
else
	bluetoothctl connect "$mac"
fi
