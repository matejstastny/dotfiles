#!/usr/bin/env bash

set -eu
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/logging.sh"

# --------------------------------------------------------------------------------------------
# pacman.sh — Arch Linux Package Installer
# --------------------------------------------------------------------------------------------
# Author: Matej Stastny
# License: MIT
# Link: https://github.com/matejstastny/dotfiles
# --------------------------------------------------------------------------------------------

if [[ "$OS_TYPE" != "Linux" ]]; then
	log warn "pacman.sh is only for Linux. Skipping."
	exit 0
fi

# Install paru (AUR helper) if missing
if ! command -v paru >/dev/null 2>&1; then
	log info "Installing paru (AUR helper)..."
	sudo pacman -S --needed --noconfirm base-devel git
	git clone https://aur.archlinux.org/paru.git /tmp/paru-install
	cd /tmp/paru-install && makepkg -si --noconfirm
	cd - && rm -rf /tmp/paru-install
	log success "paru installed"
fi

# Official packages
PACKAGES=(
	# Hyprland stack
	hyprland
	hyprpaper
	xdg-desktop-portal-hyprland
	xdg-desktop-portal-gtk
	polkit-gnome

	# Bar, launcher, notifications
	waybar
	rofi-wayland
	mako

	# Terminal & shell
	zsh
	tmux
	starship
	zsh-syntax-highlighting
	zsh-autosuggestions
	zoxide

	# Editor
	neovim

	# Git
	git
	git-delta
	lazygit

	# CLI tools
	bat
	eza
	fzf
	fastfetch
	btop
	tree
	wget
	curl
	bash

	# Screenshot & clipboard
	grim
	slurp
	wl-clipboard
	cliphist

	# Media
	playerctl

	# Brightness
	brightnessctl

	# Audio
	pipewire
	wireplumber
	pipewire-pulse
	pavucontrol

	# Wayland compat
	qt5-wayland
	qt6-wayland
	qt6ct
	nwg-look

	# Fonts
	ttf-nerd-fonts-symbols-mono
	noto-fonts
	noto-fonts-emoji

	# Dev tools
	go
	nodejs
	npm
	python
	python-pipx

	# Apps
	firefox
	thunar

	# Network
	networkmanager
	network-manager-applet
)

# AUR packages
AUR_PACKAGES=(
	ghostty
	vesktop-bin
	papirus-icon-theme-git
)

log info "Updating system..."
paru -Syu --noconfirm

log info "Installing packages..."
paru -S --needed --noconfirm "${PACKAGES[@]}" || log warn "Some packages failed to install."

log info "Installing AUR packages..."
paru -S --needed --noconfirm "${AUR_PACKAGES[@]}" || log warn "Some AUR packages failed to install."

# Enable NetworkManager
if ! systemctl is-enabled NetworkManager >/dev/null 2>&1; then
	log info "Enabling NetworkManager..."
	sudo systemctl enable --now NetworkManager
fi

# Set zsh as default shell
if [[ "$SHELL" != "$(command -v zsh)" ]]; then
	log info "Setting zsh as default shell..."
	chsh -s "$(command -v zsh)"
fi

log celebrate "All done!"
