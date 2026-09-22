#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/keshavbhatt/whatsie.git"
SOURCE_DIR="$HOME/devel/whatsie"
BUILD_DIR="$SOURCE_DIR/build"
INSTALL_PREFIX="$HOME/.local"

echo "==> Installing build dependencies..."
sudo dnf install -y \
	cmake \
	gcc-c++ \
	git \
	ninja-build \
	qt6-qtbase-devel \
	qt6-qtsvg-devel \
	qt6-qttools-devel \
	qt6-qtwebengine-devel

QT_VERSION=$(qmake6 -query QT_VERSION)
if [[ $(printf '%s\n' "6.11" "$QT_VERSION" | sort -V | head -n1) != "6.11" ]]; then
	echo "==> Whatsie requires Qt 6.11 or newer, but Fedora provided Qt $QT_VERSION."
	echo "    Update Fedora or install a newer system Qt, then run this script again."
	exit 1
fi

if [ -d "$SOURCE_DIR/.git" ]; then
	ORIGIN_URL=$(git -C "$SOURCE_DIR" remote get-url origin 2>/dev/null || true)
	if [ "$ORIGIN_URL" != "$REPO_URL" ]; then
		echo "==> $SOURCE_DIR is not a Whatsie checkout, refusing to overwrite it."
		exit 1
	fi

	echo "==> Updating Whatsie source..."
	git -C "$SOURCE_DIR" fetch --tags --force --prune --prune-tags
else
	if [ -e "$SOURCE_DIR" ]; then
		echo "==> $SOURCE_DIR already exists and is not a Git checkout, refusing to overwrite it."
		exit 1
	fi

	echo "==> Cloning Whatsie source..."
	mkdir -p "$(dirname "$SOURCE_DIR")"
	git clone "$REPO_URL" "$SOURCE_DIR"
fi

LATEST_TAG=$(git -C "$SOURCE_DIR" tag --sort=-version:refname | head -n1)
CURRENT_TAG=$(git -C "$SOURCE_DIR" describe --tags --exact-match HEAD 2>/dev/null || true)
if [ "$CURRENT_TAG" = "$LATEST_TAG" ]; then
	echo "==> Whatsie source is already at $LATEST_TAG."
else
	echo "==> Switching Whatsie from ${CURRENT_TAG:-an untagged commit} to $LATEST_TAG..."
fi
git -C "$SOURCE_DIR" checkout --detach "$LATEST_TAG"

echo "==> Building Whatsie $LATEST_TAG..."
cmake -S "$SOURCE_DIR" -B "$BUILD_DIR" -G Ninja \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
	-DWHATSIE_BUILD_TESTS=OFF
cmake --build "$BUILD_DIR" --parallel

echo "==> Installing Whatsie to $INSTALL_PREFIX..."
cmake --install "$BUILD_DIR"
command -v update-desktop-database &>/dev/null && \
	update-desktop-database "$INSTALL_PREFIX/share/applications" 2>/dev/null || true

echo "==> Whatsie installed. Launch it with: whatsie"
