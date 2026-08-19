#!/usr/bin/env bash
set -euo pipefail

log() {
	echo -e "\033[35m==> $*\033[0m"
}

exec > >(tee -a "$HOME/hypr-install.log") 2>&1

log "Asahi Fedora Linux Hyprland installer"
log "Updating system..."
sudo dnf update -y

log "Enabling lionheartp/Hyprland COPR..."
sudo dnf copr enable -y lionheartp/Hyprland

log "Installing hypr ecosystem from copr..."
sudo dnf install -y \
	hyprland \
	hypridle \
	hyprpicker \
	hyprwayland-scanner \
	xdg-desktop-portal-hyprland \
	xdg-desktop-portal-gtk

log "Installing PAM service for the quickshell lockscreen..."
if [ ! -f /etc/pam.d/quickshell-lock ]; then
	echo 'auth        include     login' | sudo tee /etc/pam.d/quickshell-lock >/dev/null
fi

log "Installing Wayland utilities..."
sudo dnf install -y \
	kitty \
	grim \
	slurp \
	wl-clipboard \
	brightnessctl \
	playerctl \
	awww \
	cliphist

log "Installing audio (PipeWire)..."
sudo dnf install -y \
	pipewire \
	pipewire-pulseaudio \
	wireplumber \
	pavucontrol \
	sound-theme-freedesktop

log "Installing system integration..."
sudo dnf install -y \
	polkit \
	lxqt-policykit \
	gnome-keyring \
	network-manager-applet \
	blueman \
	thunar

log "Installing fonts..."
sudo dnf install -y \
	fontawesome-fonts \
	google-noto-emoji-fonts

log "Enabling PipeWire user services..."
systemctl --user enable --now pipewire pipewire-pulse wireplumber || true

echo ""
echo "Done!"
