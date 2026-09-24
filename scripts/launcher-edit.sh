#!/usr/bin/env bash
#@ open a launcher app's .desktop file in vscode
id="$1"
[ -z "$id" ] && exit 1

IFS=':' read -ra dirs <<<"${XDG_DATA_HOME:-$HOME/.local/share}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

path=""
for dir in "${dirs[@]}"; do
	candidate="$dir/applications/$id.desktop"
	if [ -f "$candidate" ]; then
		path="$candidate"
		break
	fi
done

if [ -z "$path" ]; then
	notify-send -t 4000 "✦ launcher" "no desktop file found for $id"
	exit 1
fi

kitty -e code "$path" &
