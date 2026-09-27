#!/usr/bin/env bash
#@ copy incoming Quick Share images to the clipboard

set -euo pipefail

DIR="${QUICKSHARE_DIR:-$HOME/quickshare}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/quickshare"
STATE_FILE="$STATE_DIR/status.json"

mkdir -p "$DIR" "$STATE_DIR"

write_state() {
	local file=$1
	local source=$2
	local format=$3
	local received=$4
	local temp="$STATE_FILE.tmp"

	jq -cn \
		--arg file "$file" \
		--arg source "$source" \
		--arg format "$format" \
		--arg received "$received" \
		'{file: $file, source: $source, format: $format, received: $received}' >"$temp"
	mv "$temp" "$STATE_FILE"
}

copy_image() {
	local file=$1
	local source=$2
	local format=$3

	write_state "$file" "$source" "$format" "$(date --iso-8601=seconds)"
	if "$HOME/dotfiles/scripts/quickshare-own.sh" "$file"; then
		notify-send -t 4000 "✦ quick share" "Copied $(basename "$file") to clipboard"
	else
		notify-send -u critical -t 6000 "✦ quick share" \
			"Received $(basename "$file") but the clipboard copy failed"
	fi
}

handle_file() {
	local file=$1
	local lower=${file,,}
	local output

	case "$lower" in
	*.heic|*.heif)
		output="${file%.*}.jpg"
		heif-convert -q 95 "$file" "$output" >/dev/null
		copy_image "$output" "$file" "jpeg"
		;;
	*.jpg|*.jpeg)
		copy_image "$file" "$file" "jpeg"
		;;
	*.png)
		copy_image "$file" "$file" "png"
		;;
	esac
}

inotifywait --monitor --quiet --event close_write,moved_to --format '%w%f' "$DIR" |
while IFS= read -r file; do
	[ -f "$file" ] || continue
	handle_file "$file"
done
