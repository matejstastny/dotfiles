#!/usr/bin/env bash
# reqs: rofi, python3, wl-copy, notify-send
# supports standard math ops + sin/cos/tan/sqrt/log/pi/e/abs/round/floor/ceil

HISTORY="${XDG_CACHE_HOME:-$HOME/.cache}/rofi-calc-history"
touch "$HISTORY" 2>/dev/null

compute() {
	python3 -c "
import sys, math
expr = sys.argv[1]
ns = {k: getattr(math, k) for k in dir(math) if not k.startswith('_')}
ns['__builtins__'] = {}
try:
    r = eval(expr, ns)
    if isinstance(r, float) and r == int(r) and abs(r) < 1e15:
        print(int(r))
    else:
        print(r)
except Exception as e:
    print('? ' + str(e))
" "$1"
}

mapfile -t history < <(tac "$HISTORY" 2>/dev/null | head -30)

choice=$(printf '%s\n' "${history[@]}" | rofi -dmenu -p "✦ calc ✦" -l "${#history[@]}")
[ -z "$choice" ] && exit 0

if [[ "$choice" == *" = "* ]]; then
	expr="${choice%% = *}"
else
	expr="$choice"
fi

result=$(compute "$expr")

if [[ "$result" == \?* ]]; then
	notify-send -t 3000 "calc" "$result" 2>/dev/null
	exec "$0"
fi

full_line="$expr = $result"

grep -vF "$expr = " "$HISTORY" >"${HISTORY}.tmp" && mv "${HISTORY}.tmp" "$HISTORY"
echo "$full_line" >>"$HISTORY"

echo -n "$result" | wl-copy 2>/dev/null
notify-send -t 2000 "$result" "copied · $full_line" 2>/dev/null

exec "$0"
