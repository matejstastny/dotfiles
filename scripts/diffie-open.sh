#!/usr/bin/env bash
set -euo pipefail

history_file="$HOME/.local/share/vscode-projects"
project_path="${1:-}"

[ -n "$project_path" ] || exit 1
mkdir -p "$(dirname "$history_file")"
touch "$history_file"

temp_file="$(mktemp)"
printf '%s\n' "$project_path" >"$temp_file"
grep -Fxv "$project_path" "$history_file" | head -49 >>"$temp_file" || true
mv "$temp_file" "$history_file"

"$HOME/.local/bin/diffie" "$project_path" >/dev/null 2>&1 &
