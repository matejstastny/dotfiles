#!/usr/bin/env bash
# Ensure brew/system python is in PATH when running as sketchybar script
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Per-core CPU usage as 0.0-1.0 (sketchybar graph range)
CORES=$(python3 -c "
import psutil
cores = psutil.cpu_percent(percpu=True, interval=0.2)
print(' '.join(str(round(c / 100.0, 3)) for c in cores))
" 2>/dev/null)

if [ -z "$CORES" ]; then
  # Fallback: total user+sys CPU from top, spread across cores
  TOTAL=$(top -l 2 -n 0 -s 1 2>/dev/null \
    | awk '/CPU usage/ {gsub(/%/,""); print $3+$5}' \
    | tail -1)
  FRAC=$(awk "BEGIN {printf \"%.3f\", ${TOTAL:-0}/100}")
  NCPU=$(sysctl -n hw.logicalcpu 2>/dev/null || echo 1)
  CORES=""
  for _ in $(seq 1 "$NCPU"); do
    CORES="$CORES $FRAC"
  done
fi

i=0
for val in $CORES; do
  sketchybar --push "cpu.$i" "$val"
  i=$((i + 1))
done
