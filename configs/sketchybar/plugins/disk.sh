#!/bin/bash

USAGE=$(df -H /System/Volumes/Data 2>/dev/null | awk 'NR==2 {print $3 "/" $2}')

sketchybar --set "$NAME" label="${USAGE:-–}"
