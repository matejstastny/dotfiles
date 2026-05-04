#!/usr/bin/env bash
set -euo pipefail

# Fedora bootstrap — installs the full Hyprland desktop stack + dev tools
# Usage: sudo bash install-fedora.sh [--skip-hyprland] [--skip-flatpak]

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
SKIP_HYPRLAND=0
SKIP_FLATPAK=0
for arg; do
  [[ $arg == --skip-hyprland ]] && SKIP_HYPRLAND=1
  [[ $arg == --skip-flatpak  ]] && SKIP_FLATPAK=1
done

is_fedora() { [[ -f /etc/os-release ]] && grep -qi '^ID=fedora' /etc/os-release; }
ensure_root() { [[ $EUID -eq 0 ]] || { echo "Run as root: sudo bash $0" >&2; exit 1; }; }

is_fedora || { echo "This script is for Fedora." >&2; exit 1; }
ensure_root

# ── RPM Fusion ────────────────────────────────────────────────────────────────
echo "→ Enabling RPM Fusion..."
dnf install -y \
  "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" \
  || true

# ── Hyprland desktop stack ────────────────────────────────────────────────────
if (( !SKIP_HYPRLAND )); then
  echo "→ Installing Hyprland desktop stack..."
  dnf install -y \
    hyprland \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    waybar \
    rofi-wayland \
    dunst \
    kitty \
    swaybg \
    hyprlock \
    hypridle \
    wlogout \
    wl-clipboard \
    cliphist \
    grim \
    slurp \
    swappy \
    polkit-gnome \
    network-manager-applet \
    playerctl \
    pamixer \
    brightnessctl \
    blueman \
    nwg-look \
    xdg-utils \
    wireplumber \
    || true
fi

# ── Dev tools ─────────────────────────────────────────────────────────────────
echo "→ Installing dev tools..."
dnf_pkgs=(
  aria2
  bat
  btop
  coreutils
  curl
  eza
  fastfetch
  ffmpeg
  fzf
  gh
  git
  git-lfs
  glow
  golang
  gradle
  ImageMagick
  lazygit
  lua
  luarocks
  maven
  neovim
  nodejs
  npm
  python3
  python3-devel
  python3-pip
  python3-pipx
  sshpass
  tmux
  tree
  unar
  trash-cli
  wget
  zoxide
  jq
)

if ! dnf install -y "${dnf_pkgs[@]}"; then
  echo "Bulk install failed — trying packages individually..."
  missing=()
  for pkg in "${dnf_pkgs[@]}"; do
    dnf install -y "$pkg" || { echo "  ✗ not found: $pkg"; missing+=("$pkg"); }
  done
  [[ ${#missing[@]} -gt 0 ]] && echo "Missing: ${missing[*]}"
fi

# ── npm globals ───────────────────────────────────────────────────────────────
if command -v npm &>/dev/null; then
  echo "→ Installing npm globals..."
  npm install -g prettier || true
fi

# ── pipx tools ────────────────────────────────────────────────────────────────
if command -v pipx &>/dev/null; then
  echo "→ Installing Python tools via pipx..."
  pipx install --force ruff || true
  pipx install --force uv   || true
fi

# ── Go tools ──────────────────────────────────────────────────────────────────
if command -v go &>/dev/null && [[ -n ${SUDO_USER:-} ]]; then
  echo "→ Installing Go tools..."
  su -l "$SUDO_USER" -c '
    export GOBIN="$HOME/.local/bin"
    mkdir -p "$GOBIN"
    go install github.com/packwiz/packwiz@latest
    go install mvdan.cc/sh/v3/cmd/shfmt@latest
  ' || true
fi

# ── Flatpak / GUI apps ────────────────────────────────────────────────────────
if (( !SKIP_FLATPAK )); then
  command -v flatpak &>/dev/null || dnf install -y flatpak || true
  if command -v flatpak &>/dev/null; then
    echo "→ Adding Flathub..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    echo "→ Installing Flatpak apps..."
    flatpak install -y flathub md.obsidian.Obsidian || true
  fi
fi

# ── Run dot ───────────────────────────────────────────────────────────────────
DOT="$REPO_ROOT/bin/dot"
if [[ -x $DOT && -n ${SUDO_USER:-} ]]; then
  echo "→ Running dot link + assets as $SUDO_USER..."
  su -l "$SUDO_USER" -c "bash '$DOT' update --force" || true
fi

echo
echo "Done. You may want to:"
echo "  • Log out and select Hyprland from your display manager"
echo "  • Run 'dot check' to verify symlinks"
echo "  • Install VS Code: https://code.visualstudio.com/docs/setup/linux"
