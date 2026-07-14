#!/usr/bin/env bash

TODO_DIR="$HOME/notes/todo"
mkdir -p "$TODO_DIR"

case "${1:-personal}" in
personal)
	file="$TODO_DIR/personal.md"
	label="personal"
	winname="todo"
	;;
stars)
	file="$TODO_DIR/stars.md"
	label="stars"
	winname="stars"
	;;
*)
	exit 1
	;;
esac

if [ ! -f "$file" ]; then
	printf "%s\n\n" "#todo #$label" >"$file"
fi

TODAY=$(date +%Y-%m-%d)
open_todos=$(grep "^- \[ \]" "$file" 2>/dev/null | sed 's/^- \[ \] //')

chosen=$(printf "%s" "$open_todos" | rofi -dmenu -name "$winname" -p "✦ $label ✦")
[ -z "$chosen" ] && exit 0

if grep -qF "- [ ] $chosen" "$file"; then
	python3 - "$file" "$chosen" <<'PY'
import sys
path, text = sys.argv[1], sys.argv[2]
with open(path) as f:
    content = f.read()
with open(path, "w") as f:
    f.write(content.replace(f"- [ ] {text}\n", f"- [x] {text}\n", 1))
PY
	notify-send -t 2000 "✦ todo" "Done: $chosen"
else
	python3 - "$file" "$TODAY" "$chosen" <<'PY'
import sys
path, date, text = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    lines = f.readlines()
lines.insert(2, f"- [ ] {date} {text}\n")
with open(path, "w") as f:
    f.writelines(lines)
PY
	notify-send -t 2000 "✦ $label" "Added: $chosen"
fi
