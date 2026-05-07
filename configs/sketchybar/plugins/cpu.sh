#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
source "$CONFIG_DIR/colors.sh"

# Per-core as 0-100 integers
CORES=$(python3 -c "
import psutil
cores = psutil.cpu_percent(percpu=True, interval=0.2)
print(' '.join(str(int(c)) for c in cores))
" 2>/dev/null)

if [ -z "$CORES" ]; then
  TOTAL=$(top -l 2 -n 0 -s 1 2>/dev/null \
    | awk '/CPU usage/ {gsub(/%/,""); print int($3+$5)}' \
    | tail -1)
  NCPU=$(sysctl -n hw.logicalcpu 2>/dev/null || echo 1)
  CORES=""
  for _ in $(seq 1 "$NCPU"); do CORES="$CORES ${TOTAL:-0}"; done
fi

# Per-core colors — cycling, same order as items/cpu.sh
COLORS=("$COLOR_MAUVE" "$COLOR_PINK" "$COLOR_LAVENDER" "$COLOR_SAPPHIRE" "$COLOR_TEAL" "$COLOR_PEACH")
NCOLORS=${#COLORS[@]}

BLOCKS=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

i=0
for pct in $CORES; do
  idx=$(( (pct * 8) / 100 ))
  [ "$idx" -gt 7 ] && idx=7
  BLOCK="${BLOCKS[$idx]}"
  COLOR="${COLORS[$((i % NCOLORS))]}"
  sketchybar --set "cpu.$i" label="$BLOCK" label.color="$COLOR"
  i=$((i + 1))
done
