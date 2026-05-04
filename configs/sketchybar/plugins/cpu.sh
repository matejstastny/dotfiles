#!/usr/bin/env bash
CPU=$(ps -A -o %cpu | awk '{s += $1} END {printf "%.0f", s > 100 ? 100 : s}')
sketchybar --set "$NAME" label="${CPU}%"
