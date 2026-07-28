#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"

echo "✦ Installing bluetooth resume fix..."

sudo cp "$DOTFILES/configs/system/bluetooth-sleep-hook" /usr/lib/systemd/system-sleep/bluetooth-fix
sudo chmod +x /usr/lib/systemd/system-sleep/bluetooth-fix

echo "✦ Done. hci_bcm4377 will be unbound/rebound after every resume."
