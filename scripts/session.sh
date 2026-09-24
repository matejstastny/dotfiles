#!/usr/bin/env bash
#@ launch or close the standard app set

here="$(dirname "$0")"

# name | pgrep -x | window class | start | close | command
apps=(
	"kitty|kitty|^kitty$|once|quit|kitty"
	"code|code|^code$|once|quit|code $HOME/dotfiles"
	"helium|f:^([^ ]*/)?helium --profile-directory=Default|^helium$|once|quit|$here/../bin/helium --profile-directory=Default"
	"obsidian|obsidian|^obsidian$|once|quit|$HOME/.local/share/obsidian/obsidian.AppImage --appimage-extract-and-run"
	"t3code|t3code|^t3code$|once|quit|$HOME/.local/share/t3code/t3code --no-sandbox"
	"vesktop|vesktop|^vesktop$|always|tray|vesktop"
	"halloy|halloy|^org.squidowl.halloy$|once|quit|halloy"
	"whatsie|whatsie|^com\.ktechpit\.whatsie$|once|tray|$HOME/.local/bin/whatsie"
)

# a bare name goes to pgrep -x; "f:<pattern>" matches the whole command line
# instead, for apps whose process name alone is ambiguous
running() {
	if [[ $1 == f:* ]]; then
		pgrep -f "${1#f:}" >/dev/null
	else
		pgrep -x "$1" >/dev/null
	fi
}

# quickshell owns both of these and clients probe for them exactly once at
# startup, so the name has to be up before anything launches or the app quietly
# degrades for its whole lifetime, with no error and no retry
wait_for() {
	local attempt

	for ((attempt = 0; attempt < 100; attempt++)); do
		if "$@" >/dev/null 2>&1; then
			return
		fi

		sleep 0.1
	done
}

# miss this and tray apps come up with no icon
tray_up() {
	[[ "$(busctl --user get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher org.kde.StatusNotifierWatcher IsStatusNotifierHostRegistered 2>/dev/null)" == "b true" ]]
}

# miss this and chromium decides the desktop has no notification daemon, then
# draws web notifications as its own borderless windows instead of sending them
# to the shell. same GetCapabilities call chromium itself makes at browser init
notifications_up() {
	busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.Notifications GetCapabilities
}

# uwsm app puts each one in its own scope under app-graphical.slice, so they die
# with the session. a scope and not a service because launchers like /usr/bin/code
# fork off the real process and exit, which would sigkill the survivors with it
spawn() {
	local name="$1"
	shift

	# without a cap, shutdown blocks on slow electron apps with the screen
	# already frozen; 5s is enough for a clean exit, stragglers get killed
	uwsm app -a "$name" -p TimeoutStopSec=5s -- "$@" >/dev/null 2>&1 &
}

start_apps() {
	local name proc class start mode cmd waited=0

	wait_for notifications_up

	for app in "${apps[@]}"; do
		IFS='|' read -r name proc class start mode cmd <<<"$app"

		if running "$proc"; then
			# a second invocation of a single-instance app just raises its window
			[[ $start == always ]] && { $cmd >/dev/null 2>&1 & }
			continue
		fi

		if [[ $mode == tray && $waited == 0 ]]; then
			wait_for tray_up
			waited=1
		fi

		spawn "$name" $cmd
	done

	# workspace-assignment rules relocate windows after they open, which races
	# our ws2 group rule; re-evaluate rules once things have settled
	(sleep 5 && hyprctl reload) &
}

close_apps() {
	local name proc class start mode cmd clients

	clients=$(hyprctl clients -j)

	for app in "${apps[@]}"; do
		IFS='|' read -r name proc class start mode cmd <<<"$app"

		if [[ $mode == tray ]]; then
			# closing the window drops these to their tray icon, killing the pid
			# would take the tray icon down with it
			while IFS= read -r addr; do
				[[ -z $addr ]] && continue
				hyprctl dispatch "hl.dsp.window.close({ window = \"address:$addr\" })" >/dev/null
			done < <(jq -r --arg c "$class" '.[] | select(.class | test($c)) | .address' <<<"$clients")
		else
			while IFS= read -r pid; do
				[[ -z $pid ]] && continue
				kill -15 "$pid" 2>/dev/null
			done < <(jq -r --arg c "$class" '.[] | select(.class | test($c)) | .pid' <<<"$clients" | sort -u)
		fi
	done
}

case "${1:-start}" in
start) start_apps ;;
close) close_apps ;;
*)
	echo "usage: ${0##*/} [start|close]" >&2
	exit 1
	;;
esac
