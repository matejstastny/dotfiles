#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "✦ ✧ ✦  Fedora Asahi dotfiles installer"
echo ""

# ── COPRs ─────────────────────────────────────────────────


# ── COPRs ─────────────────────────────────────────────────
echo "✦ Enabling COPRs..."

# hyprlock, swww, and other Hyprland ecosystem tools
sudo dnf copr enable -y solopasha/hyprland

# SwayNotificationCenter (swaync)
sudo dnf copr enable -y erikreider/SwayNotificationCenter

# ── Main packages ─────────────────────────────────────────
echo ""
echo "✦ Installing packages..."

sudo dnf install -y \
    waybar \
    wofi \
    wlogout \
    swaync \
    hyprlock \
    swww \
    wl-clipboard \
    bluez \
    bluez-tools \
    blueman \
    grim \
    slurp \
    pipewire \
    pipewire-pulseaudio \
    wireplumber \
    pavucontrol \
    brightnessctl \
    playerctl \
    network-manager-applet \
    libnotify \
    nwg-look \
    papirus-icon-theme

# ── cliphist (Go binary, not in Fedora repos) ─────────────
echo ""
echo "✦ Installing cliphist via Go..."
if command -v go &>/dev/null; then
    go install github.com/sentriz/cliphist@latest
    echo "  installed to $GOPATH/bin/cliphist"
else
    echo "  warning: Go not found — install cliphist manually:"
    echo "  https://github.com/sentriz/cliphist/releases"
fi

# ── GTK Theme: Catppuccin Mocha Mauve ────────────────────
echo ""
echo "✦ Installing Catppuccin GTK theme..."
THEMES_DIR="$HOME/.local/share/themes"
mkdir -p "$THEMES_DIR"
CATPPUCCIN_DIR="catppuccin-mocha-mauve-standard+default"
if [ -d "$THEMES_DIR/$CATPPUCCIN_DIR" ]; then
    echo "  already installed, skipping"
else
    TMP=$(mktemp -d)
    LATEST=$(curl -fsSL https://api.github.com/repos/catppuccin/gtk/releases/latest \
        | grep '"tag_name"' | cut -d'"' -f4)
    curl -fsSL \
        "https://github.com/catppuccin/gtk/releases/download/${LATEST}/${CATPPUCCIN_DIR}.zip" \
        -o "$TMP/catppuccin-gtk.zip"
    unzip -q "$TMP/catppuccin-gtk.zip" -d "$THEMES_DIR"
    rm -rf "$TMP"
    echo "  installed Catppuccin Mocha Mauve $LATEST"
fi

# ── Rose Pine Hyprcursor ──────────────────────────────────
echo ""
echo "✦ Installing rose-pine-hyprcursor..."
ICONS_DIR="$HOME/.local/share/icons"
mkdir -p "$ICONS_DIR"
if [ -d "$ICONS_DIR/rose-pine-hyprcursor" ]; then
    echo "  already installed, skipping"
else
    TMP=$(mktemp -d)
    git clone --depth 1 https://github.com/ndom91/rose-pine-hyprcursor "$TMP/rose-pine-hyprcursor"
    cp -r "$TMP/rose-pine-hyprcursor" "$ICONS_DIR/rose-pine-hyprcursor"
    rm -rf "$TMP"
    echo "  installed rose-pine-hyprcursor"
fi

# ── Font: Maple Mono NF ───────────────────────────────────
echo ""
echo "✦ Installing Maple Mono NF..."
FONT_DIR="$HOME/.local/share/fonts/MapleMono"
if fc-list | grep -qi "Maple Mono"; then
    echo "  already installed, skipping"
else
    mkdir -p "$FONT_DIR"
    TMP=$(mktemp -d)
    # Download latest release from GitHub
    LATEST=$(curl -fsSL https://api.github.com/repos/subframe7536/maple-font/releases/latest \
        | grep '"tag_name"' | cut -d'"' -f4)
    curl -fsSL \
        "https://github.com/subframe7536/maple-font/releases/download/${LATEST}/MapleMono-NF.zip" \
        -o "$TMP/maple.zip"
    unzip -q "$TMP/maple.zip" -d "$FONT_DIR"
    fc-cache -fv
    rm -rf "$TMP"
    echo "  installed Maple Mono NF $LATEST"
fi

# ── Bluetooth service ─────────────────────────────────────
echo ""
echo "✦ Enabling bluetooth..."
sudo systemctl enable --now bluetooth.service

# ── Wallpaper directory ───────────────────────────────────
mkdir -p "$HOME/Pictures/Screenshots"
mkdir -p "$HOME/Pictures/Wallpapers"

# ── Link dotfiles ─────────────────────────────────────────
echo ""
echo "✦ Linking dotfiles..."
python3 "$DOTFILES_DIR/bin/link"

# ── GTK / gsettings ───────────────────────────────────────
echo ""
echo "✦ Applying GTK settings..."
gsettings set org.gnome.desktop.interface gtk-theme     'catppuccin-mocha-mauve-standard+default'
gsettings set org.gnome.desktop.interface icon-theme    'Papirus-Dark'
gsettings set org.gnome.desktop.interface font-name     'Maple Mono NF 11'
gsettings set org.gnome.desktop.interface cursor-theme  'rose-pine-hyprcursor'
gsettings set org.gnome.desktop.interface cursor-size   24
gsettings set org.gnome.desktop.interface color-scheme  'prefer-dark'

echo ""
echo "✦ ✧ ✦  Done! Restart Hyprland to apply the Ellie theme."
echo ""
echo "Next steps:"
echo "  1. Set a wallpaper:  swww img ~/Pictures/Wallpapers/your-image.jpg"
echo "  2. Reload waybar:    killall waybar && waybar &"
echo "  3. Test lock screen: hyprlock"
echo ""
