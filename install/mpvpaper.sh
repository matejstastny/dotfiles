#!/usr/bin/env bash
#@ install mpvpaper for live (video) wallpapers

set -euo pipefail

echo "✦ Enabling COPR (same one awww comes from)..."
sudo dnf copr enable -y lionheartp/Hyprland

echo "✦ Installing mpvpaper..."
sudo dnf install -y mpvpaper mpv-libs ffmpeg

echo "✦ Done. set-wallpaper now routes video files through mpvpaper."
