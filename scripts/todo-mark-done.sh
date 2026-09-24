#!/usr/bin/env bash
#@ mark a todo line done, used by the quickshell todo picker
file="$1"
text="$2"
[ -z "$file" ] && exit 1
[ -z "$text" ] && exit 1

python3 - "$file" "$text" <<'PY'
import sys
path, text = sys.argv[1], sys.argv[2]
with open(path) as f:
    content = f.read()
with open(path, "w") as f:
    f.write(content.replace(f"- [ ] {text}\n", f"- [x] {text}\n", 1))
PY

notify-send -t 2000 "✦ todo" "Done: $text" 2>/dev/null
