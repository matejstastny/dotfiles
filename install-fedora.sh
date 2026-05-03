#!/usr/bin/env bash
set -euo pipefail

# Fedora installer for Brewfile items (best-effort)
# Run with: sudo bash install-fedora.sh

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

ensure_root() {
  if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (sudo)." >&2
    exit 1
  fi
}

is_fedora() {
  [ -f /etc/os-release ] && grep -qi '^ID=fedora' /etc/os-release
}

enable_rpmfusion() {
  echo "Enabling RPM Fusion (free + nonfree) repos..."
  dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" || true
}

main() {
  if ! is_fedora; then
    echo "This script is intended for Fedora systems." >&2
    exit 1
  fi

  ensure_root

  # Recommended: enable RPM Fusion for multimedia (ffmpeg) and some third-party packages
  enable_rpmfusion

  # Core dnf package mapping (best-effort)
  dnf_pkgs=(
    aria2
    bat
    blueman
    btop
    coreutils
    curl
    podman
    podman-docker
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
    jenv
    lazygit
    lua
    luarocks
    maven
    neovim
    nodejs
    protobuf-compiler
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
  )

  echo "Installing DNF packages (this may include packages provided by RPM Fusion)..."
  if ! dnf -y install "${dnf_pkgs[@]}"; then
    echo "Bulk install failed; attempting per-package install to report missing packages..."
    missing=()
    for p in "${dnf_pkgs[@]}"; do
      if ! dnf -y install "$p"; then
        echo "Package not available via dnf: $p"
        missing+=("$p")
      fi
    done
    if [ ${#missing[@]} -ne 0 ]; then
      echo "The following packages were not installed via dnf: ${missing[*]}"
      echo "You may need third-party repos (COPR) or to install from source/binaries."
    fi
  fi

  # Node global packages
  if command -v npm >/dev/null 2>&1; then
    echo "Installing npm global packages: prettier"
    npm install -g prettier || true
  else
    echo "npm not found; skipping npm global packages (install nodejs to enable)."
  fi

  # pipx and python tools
  if command -v pipx >/dev/null 2>&1; then
    echo "Installing Python tools via pipx: ruff"
    pipx install --force ruff || true
  else
    echo "pipx not found; attempting to install pipx via pip"
    python3 -m pip install --user pipx || true
    export PATH="$HOME/.local/bin:$PATH"
    if command -v pipx >/dev/null 2>&1; then
      pipx install --force ruff || true
    else
      echo "pipx still not available; please install pipx manually." >&2
    fi
  fi

  # Go tools
  if command -v go >/dev/null 2>&1; then
    echo "Installing Go tools to $HOME/.local/bin"
    export GOBIN="$HOME/.local/bin"
    mkdir -p "$GOBIN"
    su -l "$SUDO_USER" -c 'export GOBIN="$HOME/.local/bin"; PATH="$HOME/.local/bin:$PATH"; go install github.com/packwiz/packwiz@latest' || true
    su -l "$SUDO_USER" -c 'export GOBIN="$HOME/.local/bin"; PATH="$HOME/.local/bin:$PATH"; go install mvdan.cc/sh/v3/cmd/shfmt@latest' || true
  else
    echo "Go not found; skipping go-based installs. Install golang (dnf) to enable."
  fi

  # Casks / GUI apps: prefer Flatpak when available, otherwise provide instructions
  echo
  echo "GUI apps (casks) - attempting Flatpak installs for known apps..."
  if ! command -v flatpak >/dev/null 2>&1; then
    echo "Flatpak not found; installing flatpak"
    dnf install -y flatpak || true
  fi
  if command -v flatpak >/dev/null 2>&1; then
    echo "Adding Flathub remote if missing..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    echo "Attempting installs (best-effort): Obsidian"
    flatpak install -y flathub md.obsidian.Obsidian || echo "Obsidian flatpak not found on Flathub or failed."
    echo "You may want to install: balenaEtcher (AppImage), Docker Desktop (podman-desktop), Visual Studio Code (from Microsoft repo or Flatpak), VNC Viewer (tigervnc)."
  else
    echo "Flatpak unavailable; skipping Flatpak installs."
  fi

  echo
  echo "Done. Review above output for any packages that failed to install."
  echo "Manual follow-ups you may want to run as your regular user (not root):"
  echo "  - Ensure $HOME/.local/bin is in your PATH"
  echo "  - pipx installs (if you prefer user-level): pipx install ruff"
  echo "  - npm global installs: npm install -g prettier"
  echo "  - Install Docker Desktop (if required) from Docker or use Podman/Podman Desktop."
  echo
}

main "$@"
