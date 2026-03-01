#!/bin/bash

# Use the data volume for accurate APFS space reporting
LABEL=$(df -H /System/Volumes/Data 2>/dev/null || df -H /)
LABEL=$(echo "$LABEL" | awk 'NR==2 {
    used = $3; total = $2
    gsub(/G$/, "", used); gsub(/G$/, "", total)
    printf "%s/%sG", used, total
}')

sketchybar --set "$NAME" label="$LABEL"
