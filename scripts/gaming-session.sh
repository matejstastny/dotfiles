#!/usr/bin/env bash
#@ barebones gaming shell run from tty

LOG="$HOME/.cache/gaming-session.log"
RC="$(mktemp)"
mkdir -p "$HOME/.cache"

cat >"$RC" <<'RCEOF'
[[ -f ~/.bashrc ]] && source ~/.bashrc
unalias game 2>/dev/null

# gamescope's own drm backend can't work on asahi, so it runs nested in cage
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

echo "steam-gs    steam in gamescope"
echo "steam-raw   steam directly, no gamescope"
echo "steam-loop  steam-gs, relaunches when it dies"
echo "exit        leave the session"
RCEOF

{
	echo "=== $(date) ==="
	cage -d -- kitty --start-as=fullscreen bash --rcfile "$RC"
	echo "=== exit $? ==="
} 2>&1 | tee -a "$LOG"

rm -f "$RC"
