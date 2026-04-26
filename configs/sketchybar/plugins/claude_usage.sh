#!/bin/bash

token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['claudeAiOauth']['accessToken'])" 2>/dev/null)

usage=$(curl -sf "https://api.anthropic.com/api/oauth/usage" \
  -H "Authorization: Bearer $token" \
  -H "anthropic-beta: oauth-2025-04-20" 2>/dev/null)

label=$(echo "$usage" | python3 -c "
import sys, json
d = json.load(sys.stdin)
s = d.get('five_hour', {}).get('utilization')
w = d.get('seven_day', {}).get('utilization')
if s is None or w is None:
    print('? · ?%')
else:
    print(f'{s:.0f}% · {w:.0f}%')
" 2>/dev/null)

sketchybar --set "$NAME" label="${label:-? · ?%}"
