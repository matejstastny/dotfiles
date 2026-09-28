#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/jellyfin/jellyfin-desktop.git"
SOURCE_DIR="${JELLYFIN_DESKTOP_SOURCE_DIR:-$HOME/src/jellyfin-desktop}"
BUILD_DIR="$SOURCE_DIR/build"

if ! command -v dnf >/dev/null; then
	echo "This installer supports Fedora and other dnf-based distributions."
	exit 1
fi

echo "==> Installing Jellyfin Desktop build dependencies..."
sudo dnf install -y \
	cmake \
	ninja-build \
	gcc-c++ \
	pkgconf-pkg-config \
	git \
	qt6-qtbase-devel \
	qt6-qtbase-private-devel \
	qt6-qtdeclarative-devel \
	qt6-qtwebengine-devel \
	qt6-qtwayland-devel \
	qt6-qtwebchannel \
	mpv-libs-devel \
	mpvqt-devel \
	libcec-devel \
	extra-cmake-modules \
	libX11-devel \
	libXrandr-devel \
	libva-devel \
	libglvnd-devel \
	mesa-libGL-devel \
	SDL2-devel \
	alsa-lib-devel \
	pulseaudio-libs-devel \
	uchardet-devel \
	fribidi-devel \
	gnutls-devel \
	harfbuzz-devel \
	freetype-devel \
	fontconfig-devel \
	zlib-ng-compat-devel

if [ -d "$SOURCE_DIR/.git" ]; then
	ORIGIN_URL=$(git -C "$SOURCE_DIR" remote get-url origin 2>/dev/null || true)
	if [ "$ORIGIN_URL" != "$REPO_URL" ] && [ "$ORIGIN_URL" != "${REPO_URL%.git}" ]; then
		echo "==> $SOURCE_DIR is not a Jellyfin Desktop checkout, refusing to overwrite it."
		exit 1
	fi

	if ! git -C "$SOURCE_DIR" diff --quiet || ! git -C "$SOURCE_DIR" diff --cached --quiet; then
		echo "==> $SOURCE_DIR has local changes, refusing to update it."
		exit 1
	fi

	echo "==> Updating Jellyfin Desktop source..."
	git -C "$SOURCE_DIR" pull --ff-only
else
	if [ -e "$SOURCE_DIR" ]; then
		echo "==> $SOURCE_DIR already exists and is not a Git checkout, refusing to overwrite it."
		exit 1
	fi

	echo "==> Cloning Jellyfin Desktop..."
	mkdir -p "$(dirname "$SOURCE_DIR")"
	git clone --recurse-submodules "$REPO_URL" "$SOURCE_DIR"
fi

echo "==> Updating submodules..."
git -C "$SOURCE_DIR" submodule update --init --recursive

echo "==> Configuring native $(uname -m) release build..."
cmake -S "$SOURCE_DIR" -B "$BUILD_DIR" -GNinja \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=/usr/local

echo "==> Building Jellyfin Desktop..."
cmake --build "$BUILD_DIR" --parallel "$(nproc)"

echo "==> Installing Jellyfin Desktop..."
sudo cmake --install "$BUILD_DIR"

echo "==> Done. Run Jellyfin Desktop with: jellyfin-desktop"
