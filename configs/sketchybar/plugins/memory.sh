#!/bin/bash

USED=$(vm_stat 2>/dev/null | awk '
    /Pages active/     {a=$3+0}
    /Pages wired/      {w=$4+0}
    /Pages occupied/   {c=$5+0}
    END {printf "%.1f", (a+w+c)*4096/1073741824}
')

TOTAL=$(sysctl -n hw.memsize | awk '{printf "%d", $1/1073741824}')

sketchybar --set "$NAME" label="${USED:-0}G / ${TOTAL}G"
