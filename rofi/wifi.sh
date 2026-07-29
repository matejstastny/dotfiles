#!/usr/bin/env bash

IFACE=$(nmcli -t -f DEVICE,TYPE device status | awk -F: '$2=="wifi"{print $1;exit}')

wifi_enabled() { [ "$(nmcli radio wifi)" = "enabled" ]; }

signal_icon() {
	local s=$1
	if [ "$s" -ge 80 ]; then
		printf '󰤨'
	elif [ "$s" -ge 60 ]; then
		printf '󰤥'
	elif [ "$s" -ge 40 ]; then
		printf '󰤢'
	elif [ "$s" -ge 20 ]; then
		printf '󰤟'
	else
		printf '󰤯'
	fi
}

lines=()
etypes=() # toggle | connected | saved | new
essids=()
econns=() # connection profile name (for saved entries)
esecs=()  # security string (for new entries)

lines+=("󰁪  Refresh")
etypes+=("refresh")
essids+=("")
econns+=("")
esecs+=("")

if wifi_enabled; then
	lines+=("󰖪  Turn WiFi off")
else
	lines+=("󰖩  Turn WiFi on")
fi
etypes+=("toggle")
essids+=("")
econns+=("")
esecs+=("")

if wifi_enabled; then
	# Build set of saved wifi connection names (profile name == SSID in most cases)
	declare -A saved_conns
	while IFS=: read -r name type; do
		[ "$type" = "802-11-wireless" ] && saved_conns["$name"]=1
	done < <(nmcli -t -f NAME,TYPE connection show 2>/dev/null)

	# Active SSID goes first
	declare -A seen
	active_ssid=$(nmcli -t -f ACTIVE,SSID dev wifi list --rescan no 2>/dev/null |
		awk -F: '$1=="yes"{print $2;exit}')
	if [ -n "$active_ssid" ]; then
		lines+=("󰤩  $active_ssid  ·  connected")
		etypes+=("connected")
		essids+=("$active_ssid")
		econns+=("")
		esecs+=("")
		seen["$active_ssid"]=1
	fi

	# Remaining visible networks sorted by signal strength
	while IFS=: read -r _active ssid signal security; do
		[ -z "$ssid" ] && continue
		[ -n "${seen[$ssid]}" ] && continue
		seen["$ssid"]=1

		icon=$(signal_icon "$signal")
		lock=""
		[ "$security" != "--" ] && [ -n "$security" ] && lock=" 󰌾"

		if [ -n "${saved_conns[$ssid]}" ]; then
			lines+=("$icon  $ssid  ·  saved$lock")
			etypes+=("saved")
			essids+=("$ssid")
			econns+=("$ssid")
			esecs+=("")
		else
			lines+=("$icon  $ssid$lock")
			etypes+=("new")
			essids+=("$ssid")
			econns+=("")
			esecs+=("$security")
		fi
	done < <(nmcli -t -f ACTIVE,SSID,SIGNAL,SECURITY dev wifi list --rescan no 2>/dev/null |
		awk -F: '!/^yes:/' |
		sort -t: -k3 -rn)
fi

idx=$(printf '%s\n' "${lines[@]}" | rofi -dmenu -i -p "✦ wifi ✦" -format i)
rofi_ret=$?
[[ $rofi_ret -ne 0 || -z "$idx" ]] && exit 0
[[ "$idx" -lt 0 ]] 2>/dev/null && exit 0

etype="${etypes[$idx]}"
essid="${essids[$idx]}"
econn="${econns[$idx]}"
esec="${esecs[$idx]}"

case "$etype" in
refresh)
	nmcli dev wifi list --rescan yes >/dev/null 2>&1 &
	exec "$0"
	;;
toggle)
	if wifi_enabled; then nmcli radio wifi off; else nmcli radio wifi on; fi
	;;
connected)
	nmcli device disconnect "$IFACE"
	;;
saved)
	nmcli connection up "$econn"
	;;
new)
	if [ -z "$esec" ] || [ "$esec" = "--" ]; then
		nmcli device wifi connect "$essid"
	else
		pass=$(rofi -dmenu -password -p "🔒 password for $essid")
		[ -z "$pass" ] && exit 0
		nmcli device wifi connect "$essid" password "$pass"
	fi
	;;
esac
