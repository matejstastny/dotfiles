#!/usr/bin/env bash

SOCK="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

output() {
    python3 - << 'EOF'
import json, subprocess, sys

try:
    clients = json.loads(subprocess.check_output(['hyprctl', '-j', 'clients']))
    active  = json.loads(subprocess.check_output(['hyprctl', '-j', 'activewindow']))
except Exception:
    print('{"text": ""}', flush=True)
    sys.exit(0)

ws2 = sorted(
    [c for c in clients if c.get('workspace', {}).get('id') == 2],
    key=lambda c: c['address']
)
if not ws2:
    print('{"text": ""}', flush=True)
    sys.exit(0)

active_addr = active.get('address', '')
dots   = ['●' if c['address'] == active_addr else '○' for c in ws2]
titles = [('→ ' if c['address'] == active_addr else '  ') + c.get('title', '')[:50]
          for c in ws2]

print(json.dumps({'text': ' '.join(dots), 'tooltip': '\n'.join(titles)}), flush=True)
EOF
}

output

socat - "UNIX-CONNECT:${SOCK}" 2>/dev/null \
    | grep --line-buffered -E '^(activewindow|openwindow|closewindow|movewindow|workspace|focusedmon)>>' \
    | while IFS= read -r _; do
        output
    done
