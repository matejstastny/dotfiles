#!/usr/bin/env bash
# the .qsb files are checked in, so this only needs running after a .vert or
# .frag changes. the flag sets are what the committed files were baked with -
# changing them rewrites every blob in the repo
set -euo pipefail
cd "$(dirname "$0")"

for stage in blob squircle; do
    for ext in vert frag; do
        [ -f "$stage.$ext" ] || continue
        qsb-qt6 --glsl "120,150,300es" --msl 12 -o "$stage.$ext.qsb" "$stage.$ext"
        echo "baked $stage.$ext.qsb"
    done
done
