#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"

echo "✦ Installing timedate polkit rule..."

sudo mkdir -p /etc/polkit-1/rules.d
sudo cp "$DOTFILES/configs/system/50-timedate.rules" /etc/polkit-1/rules.d/50-timedate.rules
sudo systemctl restart polkit

echo "✦ Done. wheel group can now set the system timezone without a password prompt."
