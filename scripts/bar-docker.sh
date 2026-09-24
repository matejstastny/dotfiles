#!/usr/bin/env bash
if ! command -v docker &>/dev/null || ! docker info &>/dev/null 2>&1; then
    printf '{"text":"󰡨","title":"docker","headline":"offline","lines":["daemon is unavailable"],"class":"offline"}\n'
    exit
fi

count=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
if [ "$count" = "0" ]; then
    printf '{"text":"󰡨","title":"docker","headline":"no containers","lines":["daemon is ready"],"class":"idle"}\n'
else
    names=$(docker ps --format "{{.Names}}  ·  {{.Image}}" 2>/dev/null | head -8)
    jq -cn --arg count "$count" --arg names "$names" \
        '{text: ("󰡨 " + $count), title: "docker", headline: ($count + " running"), lines: ($names | split("\n")), class: "running"}'
fi
