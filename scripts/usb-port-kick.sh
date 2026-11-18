#!/usr/bin/env bash
#@ cycle usb switcher hub ports with no child attached (the switcher reconnect race leaves them wedged, either "powered" or "not attached")
#@ actual root logic lives in /usr/local/bin/usb-port-kick, a passwordless-scoped helper (see /etc/polkit-1/rules.d/49-usb-port-kick.rules)

pkexec /usr/local/bin/usb-port-kick
case $? in
0) notify-send -t 3000 "✦ usb" "port reloaded" ;;
1) notify-send -t 3000 "✦ usb" "no stuck port found" ;;
2) notify-send -t 3000 "✦ usb" "switcher hub not found, is it plugged in?" ;;
*) notify-send -t 3000 "✦ usb" "port reload denied or failed" ;;
esac
