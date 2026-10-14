#!/usr/bin/env bash
#@ apply a wallpaper, routing videos through mpvpaper and stills through awww

set -e

bin_dir="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

path="$1"
output="$2"
[ -z "$path" ] && exit 1

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-thumbs"
mkdir -p "$cache_dir"

# grow the new wallpaper out of a circle centred on the cursor, falling back
# to the screen centre when hyprland can't be asked
transition_pos=center
if cursor=$(hyprctl -j cursorpos 2>/dev/null) && mon=$(hyprctl -j monitors 2>/dev/null); then
	# awww reads integers as pixels and floats as fractions, so the clamp keeps
	# both components strictly fractional
	transition_pos=$(jq -nr --argjson c "$cursor" --argjson m "$mon" '
		def clamp: [[., 0.001] | max, 0.999] | min;
		($m[] | select(.focused)) as $f
		| (($c.x - $f.x) / ($f.width / $f.scale) | clamp) as $x
		| (($c.y - $f.y) / ($f.height / $f.scale) | clamp) as $y
		| "\($x),\($y)"
	' 2>/dev/null) || transition_pos=center
fi

awww_args=(
	--transition-type grow
	--transition-pos "$transition_pos"
	--invert-y
	--transition-duration 0.9
	--transition-bezier .25,.1,.25,1
	--transition-fps 60
)
[ -n "$output" ] && awww_args+=(-o "$output")

# bounded so a dead awww-daemon fails loudly instead of hanging forever -
# live wallpapers in particular must not block on it
await_awww() {
	local tries=0
	until awww query &>/dev/null; do
		tries=$((tries + 1))
		[ "$tries" -ge 100 ] && return 1
		sleep 0.1
	done
	[ -z "$output" ] && return 0
	tries=0
	until awww query | grep -q "^: ${output}:"; do
		tries=$((tries + 1))
		[ "$tries" -ge 50 ] && break
		sleep 0.2
	done
}

if [ "$("$bin_dir/wallpaper-kind.sh" "$path")" != live ]; then
	pkill -x mpvpaper 2>/dev/null || true
	pkill -x mpvpaper-holder 2>/dev/null || true
	await_awww || :
	exec awww img "$path" "${awww_args[@]}"
fi

# stills first: gives an instant frame while mpv spins up, and leaves a
# matching fallback on the background layer if mpvpaper ever dies
poster="$cache_dir/$(basename "$path").poster.jpg"
if [ ! -f "$poster" ] || [ "$path" -nt "$poster" ]; then
	ffmpeg -y -v error -i "$path" -frames:v 1 -vf "scale='min(2560,iw)':-2" "$poster"
fi
await_awww || :
awww img "$poster" "${awww_args[@]}" || true

pkill -x mpvpaper 2>/dev/null || true
pkill -x mpvpaper-holder 2>/dev/null || true
exec mpvpaper -f -p -a MAX \
	-o "no-audio loop-file=inf panscan=1.0 hwdec=auto-safe" \
	ALL "$path"
