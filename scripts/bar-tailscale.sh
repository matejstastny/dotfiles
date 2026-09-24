#!/usr/bin/env bash
if ! command -v tailscale &>/dev/null; then
    printf '{"text":"","class":"absent"}\n'
    exit
fi

status=$(tailscale status --json 2>/dev/null) || {
    printf '{"text":"󰒎","title":"tailscale","headline":"offline","lines":["unable to reach tailscaled"],"class":"offline"}\n'
    exit
}

state=$(printf '%s' "$status" | jq -r '.BackendState')
if [ "$state" = "Running" ]; then
    ip=$(printf '%s' "$status" | jq -r '.TailscaleIPs[0] // "?"')
    host=$(printf '%s' "$status" | jq -r '.Self.HostName // "?"')
    jq -cn --arg ip "$ip" --arg host "$host" \
        '{text: "󰒍", title: "tailscale", headline: $host, lines: [$ip], class: "connected"}'
else
    jq -cn --arg s "$state" \
        '{text: "󰒎", title: "tailscale", headline: $s, lines: ["not connected"], class: "offline"}'
fi
