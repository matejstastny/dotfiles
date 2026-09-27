#!/usr/bin/env bash
#@ hand a Quick Share image to a fresh clipboard owner

set -euo pipefail

file=$1
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/quickshare"
pid_file="$state_dir/clipboard-owner.pid"

mkdir -p "$state_dir"

# Qt needs a compositor; systemd may have started us before uwsm exported it
if [ -z "${WAYLAND_DISPLAY:-}" ]; then
	for socket in "${XDG_RUNTIME_DIR:-/run/user/$UID}"/wayland-[0-9]*; do
		[ -S "$socket" ] || continue
		WAYLAND_DISPLAY=$(basename "$socket")
		export WAYLAND_DISPLAY
		break
	done
fi
[ -n "${WAYLAND_DISPLAY:-}" ] || exit 1
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland}"

if [ -s "$pid_file" ]; then
	old_pid=$(<"$pid_file")
	if kill -0 "$old_pid" 2>/dev/null; then
		kill "$old_pid"
	fi
	rm -f "$pid_file"
fi

magick "$file" png:- | "$HOME/dotfiles/scripts/quickshare-clipboard-owner.py" "$file" "$pid_file" &
owner=$!

for _ in $(seq 50); do
	if [ -s "$pid_file" ]; then
		exit 0
	fi
	kill -0 "$owner" 2>/dev/null || break
	sleep 0.1
done

[ -s "$pid_file" ]
