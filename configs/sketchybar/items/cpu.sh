#!/usr/bin/env bash
source "$CONFIG_DIR/colors.sh"

NCPU=$(sysctl -n hw.logicalcpu)

# Colors cycle per core — mauve, pink, lavender, sapphire, teal, peach
COLORS=("$COLOR_MAUVE" "$COLOR_PINK" "$COLOR_LAVENDER" "$COLOR_SAPPHIRE" "$COLOR_TEAL" "$COLOR_PEACH")
FILLS=("$COLOR_MAUVE_FILL" "$COLOR_PINK_FILL" "$COLOR_LAVENDER_FILL" "$COLOR_SAPPHIRE_FILL" "$COLOR_TEAL_FILL" "$COLOR_PEACH_FILL")
NCOLORS=${#COLORS[@]}

for i in $(seq 0 $((NCPU - 1))); do
  COL_IDX=$((i % NCOLORS))
  sketchybar --add graph "cpu.$i" right 18 \
    --set "cpu.$i" \
      graph.color="${COLORS[$COL_IDX]}" \
      graph.fill_color="${FILLS[$COL_IDX]}" \
      graph.line_width=1 \
      background.color="$COLOR_TRANSPARENT" \
      background.height=26 \
      background.border_width=0 \
      label.drawing=off \
      icon.drawing=off \
      width=18 \
      update_freq=0 \
      script=""
done

# Hidden driver — runs every 2s and pushes 0.0-1.0 values to all graph items
sketchybar --add item cpu_driver right \
  --set cpu_driver \
    update_freq=2 \
    script="$PLUGIN_DIR/cpu.sh" \
    icon.drawing=off \
    label.drawing=off \
    background.color="$COLOR_TRANSPARENT" \
    background.height=0 \
    width=0

# Build bracket member list: driver first (hidden, leftmost), then graphs
BRACKET_ITEMS="cpu_driver"
for i in $(seq 0 $((NCPU - 1))); do
  BRACKET_ITEMS="$BRACKET_ITEMS cpu.$i"
done

# shellcheck disable=SC2086
sketchybar --add bracket cpu_bracket $BRACKET_ITEMS \
  --set cpu_bracket \
    background.color="$COLOR_SURFACE" \
    background.corner_radius=10 \
    background.height=30 \
    background.drawing=on
