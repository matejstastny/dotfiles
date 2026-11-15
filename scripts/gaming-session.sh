#!/usr/bin/env bash
#@ barebones gaming shell run from tty

LOG="$HOME/.cache/gaming-session.log"
mkdir -p "$HOME/.cache"

if ! command -v labwc >/dev/null; then
	echo "labwc missing installing..." >&2
	sudo dnf install -y labwc
fi

RC="$(mktemp)"
trap 'rm -f "$RC"' EXIT

[[ -f ~/.config/uwsm/env ]] && source ~/.config/uwsm/env

export XDG_CURRENT_DESKTOP=labwc:wlroots
export XDG_SESSION_TYPE=wayland

export XKB_DEFAULT_LAYOUT="us,cz"
export XKB_DEFAULT_VARIANT=",qwerty"
export XKB_DEFAULT_OPTIONS="ctrl:swap_lwin_lctl"

cat >"$RC" <<'RCEOF'
[[ -f ~/.bashrc ]] && source ~/.bashrc
unalias game 2>/dev/null

# gamescope's own drm backend can't work on asahi, so it runs nested in labwc
steam-gs() { gamescope -f -e -- steam -tenfoot "$@"; }
steam-raw() { steam -tenfoot "$@"; }

# relaunch loop: reruns steam until you press n
steam-loop() {
	local ans
	while true; do
		steam-gs "$@"
		read -rp "steam exited ($?), relaunch? [Y/n] " ans
		[[ $ans == [nN]* ]] && break
	done
}

outputs() { wlr-randr; }

# panel only, the external stays connected but dark so games land on eDP-1
panel() {
	wlr-randr --output eDP-1 --on
	local out
	for out in $(wlr-randr --json | jq -r '.[].name'); do
		[[ $out == eDP-1 ]] || wlr-randr --output "$out" --off
	done
}

both() {
	local out
	for out in $(wlr-randr --json | jq -r '.[].name'); do
		wlr-randr --output "$out" --on
	done
}

# 1 is native and what games want, bump it only if the ui is unreadable
scale() { wlr-randr --output "${2:-eDP-1}" --scale "${1:-1}"; }

# bounce an external through another mode to clear the apple dcp valid_mode:0 race
bounce() {
	local out="${1:-DP-1}" modes alt
	modes=$(wlr-randr --json | jq -r --arg o "$out" \
		'.[] | select(.name == $o) | .modes[] | "\(.width)x\(.height)@\(.refresh)Hz"')
	if [[ -z $modes ]]; then
		echo "$out not connected" >&2
		return 1
	fi
	alt=$(sed -n 2p <<<"$modes")
	[[ -z $alt ]] && alt=$(head -1 <<<"$modes")
	wlr-randr --output "$out" --mode "$alt" && sleep 5 && wlr-randr --output "$out" --preferred
}

cat <<'HELP'
steam-gs    steam in gamescope
steam-raw   steam directly, no gamescope
steam-loop  steam-gs, relaunches when it dies
outputs     list outputs and modes
panel       laptop panel only
both        all outputs back on
scale       scale [n] [output], 1 = native
bounce      bounce [output] through another mode, fixes valid_mode:0
exit        leave the session

alt-tab cycle windows   alt-w close   alt-f fullscreen   alt-return kitty
alt-shift-k hand all keys to the game   alt-shift-escape kill a stuck window
alt-shift-g quit the wm
HELP
RCEOF

{
	echo "=== $(date) ==="
	# -S ends the session when the shell exits, same feel as the old cage run
	labwc -S "kitty -o font_size=15 -o background_opacity=1 --start-as=fullscreen bash --rcfile $RC"
	echo "=== exit $? ==="
} 2>&1 | tee -a "$LOG"
