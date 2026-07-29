#!/usr/bin/env bash
cliphist list |
	rofi -dmenu -p "✦ clipboard ✦" |
	cliphist decode |
	wl-copy
