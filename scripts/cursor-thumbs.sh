#!/usr/bin/env bash
#@ list installed cursor themes with cached preview thumbnails, current theme pinned first

set -e

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/cursor-thumbs"
state="${XDG_STATE_HOME:-$HOME/.local/state}/cursor"
sizes="${XDG_STATE_HOME:-$HOME/.local/state}/cursor-sizes"
mkdir -p "$cache_dir"

current=""
[ -f "$state" ] && current=$(head -n1 "$state")
[ -z "$current" ] && current="${XCURSOR_THEME:-}"

find -L "$HOME/.local/share/icons" "$HOME/.icons" /usr/share/icons \
	-mindepth 1 -maxdepth 1 -type d 2>/dev/null |
	while IFS= read -r theme_dir; do
		name=$(basename "$theme_dir")

		pointer=""
		for candidate in left_ptr default arrow; do
			[ -f "$theme_dir/cursors/$candidate" ] && pointer="$theme_dir/cursors/$candidate" && break
		done
		[ -z "$pointer" ] && continue

		thumb="$cache_dir/$name.png"
		if [ ! -f "$thumb" ] || [ "$pointer" -nt "$thumb" ]; then
			tmp=$(mktemp -d)
			xcur2png -q -d "$tmp" -c "$tmp/conf" "$pointer" 2>/dev/null || true
			largest=$(identify -format '%w %f\n' "$tmp"/*.png 2>/dev/null | sort -n -r | head -n1 | cut -d' ' -f2)
			[ -n "$largest" ] && cp "$tmp/$largest" "$thumb"
			rm -rf "$tmp"
		fi
		[ -f "$thumb" ] || continue

		is_current=0
		[ "$name" = "$current" ] && is_current=1

		size=""
		[ -f "$sizes" ] && size=$(awk -F'\t' -v t="$name" '$1 == t { print $2 }' "$sizes")
		[ "$is_current" = "1" ] && [ -z "$size" ] && size="${XCURSOR_SIZE:-}"
		size="${size:-24}"

		printf '%s\t%s\t%s\t%s\n' "$is_current" "$name" "$thumb" "$size"
	done | sort -t $'\t' -k1,1r -k2,2 -s
