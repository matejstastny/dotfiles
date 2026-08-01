#!/usr/bin/env bash
PID_FILE="/tmp/gpu-screen-recorder.pid"

if [ ! -f "$PID_FILE" ] || ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo '{"text": ""}'
    exit 0
fi

start=$(stat -c %Y "$PID_FILE")
now=$(date +%s)
elapsed=$((now - start))
mins=$((elapsed / 60))
secs=$((elapsed % 60))
printf '{"text": "%d:%02d", "class": "recording"}\n' "$mins" "$secs"
