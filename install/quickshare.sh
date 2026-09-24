#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

sudo install -D -m 0644 \
	"$DOTFILES_DIR/configs/system/quickshare-taildrop.service" \
	/etc/systemd/system/quickshare-taildrop.service
sudo systemctl daemon-reload
sudo systemctl enable --now quickshare-taildrop.service
systemctl --user daemon-reload
systemctl --user enable --now quickshare-clipboard.service
