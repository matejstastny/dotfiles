#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"

echo "✦ Installing power management config..."

# logind: explicit lid-close → suspend
sudo mkdir -p /etc/systemd/logind.conf.d
sudo cp "$DOTFILES/configs/system/logind-power.conf" /etc/systemd/logind.conf.d/power.conf
sudo systemctl restart systemd-logind

# sleep hook: lock screen before suspend
sudo cp "$DOTFILES/configs/system/lock-sleep-hook" /usr/lib/systemd/system-sleep/lock
sudo chmod +x /usr/lib/systemd/system-sleep/lock

echo "✦ Done. Close the lid to suspend; the lockscreen will run on wake."
