#!/usr/bin/env bash
if ! command -v tailscale &>/dev/null; then
    printf '{"text":"","class":"absent"}\n'
    exit
fi

status=$(tailscale status --json 2>/dev/null) || {
    printf '{"text":"󰒎","tooltip":"Tailscale: offline","class":"offline"}\n'
    exit
}

state=$(printf '%s' "$status" | jq -r '.BackendState')
if [ "$state" = "Running" ]; then
    ip=$(printf '%s' "$status" | jq -r '.TailscaleIPs[0] // "?"')
    host=$(printf '%s' "$status" | jq -r '.Self.HostName // "?"')
    jq -cn --arg ip "$ip" --arg host "$host" \
        '{"text":"󰒍","tooltip":("󰒍 " + $host + "\n" + $ip),"class":"connected"}'
else
    jq -cn --arg s "$state" \
        '{"text":"󰒎","tooltip":("Tailscale: " + $s),"class":"offline"}'
fi
