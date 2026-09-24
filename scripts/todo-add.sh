#!/usr/bin/env bash
#@ insert a new todo line, used by the quickshell todo picker
file="$1"
text="$2"
[ -z "$file" ] && exit 1
[ -z "$text" ] && exit 1

python3 - "$file" "$text" <<'PY'
import sys
from datetime import date
path, text = sys.argv[1], sys.argv[2]
today = date.today().isoformat()
with open(path) as f:
    lines = f.readlines()
lines.insert(2, f"- [ ] {today} {text}\n")
with open(path, "w") as f:
    f.writelines(lines)
PY

notify-send -t 2000 "✦ todo" "Added: $text" 2>/dev/null
