#!/usr/bin/env bash
PAGE_SIZE=$(pagesize)
STATS=$(vm_stat)
ACTIVE=$(echo "$STATS" | awk '/Pages active/    {gsub(/\./, "", $3); print $3}')
WIRED=$(echo "$STATS"  | awk '/Pages wired down/{gsub(/\./, "", $4); print $4}')
TOTAL=$(( $(sysctl -n hw.memsize) / 1073741824 ))
USED=$(( (ACTIVE + WIRED) * PAGE_SIZE / 1073741824 ))
sketchybar --set "$NAME" label="${USED}G / ${TOTAL}G"
