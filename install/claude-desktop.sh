#!/usr/bin/env bash
#@ build and install Claude Desktop via the claude-desktop-rpm spec (Fedora Asahi aarch64)
set -euo pipefail

REPO_URL="https://github.com/christian-korneck/claude-desktop-rpm.git"
SOURCE_DIR="${CLAUDE_DESKTOP_RPM_SOURCE_DIR:-$HOME/src/claude-desktop-rpm}"
ARCH="$(uname -m)"

if ! command -v dnf >/dev/null; then
	echo "This installer supports Fedora and other dnf-based distributions."
	exit 1
fi

echo "==> Installing build dependencies..."
sudo dnf install -y \
	rpmdevtools \
	p7zip-plugins \
	icoutils \
	nodejs \
	npm \
	desktop-file-utils

if [ -d "$SOURCE_DIR/.git" ]; then
	ORIGIN_URL=$(git -C "$SOURCE_DIR" remote get-url origin 2>/dev/null || true)
	if [ "$ORIGIN_URL" != "$REPO_URL" ] && [ "$ORIGIN_URL" != "${REPO_URL%.git}" ]; then
		echo "==> $SOURCE_DIR is not a claude-desktop-rpm checkout, refusing to overwrite it."
		exit 1
	fi

	if ! git -C "$SOURCE_DIR" diff --quiet || ! git -C "$SOURCE_DIR" diff --cached --quiet; then
		echo "==> $SOURCE_DIR has local changes, refusing to update it."
		exit 1
	fi

	echo "==> Updating claude-desktop-rpm source..."
	git -C "$SOURCE_DIR" pull --ff-only
else
	if [ -e "$SOURCE_DIR" ]; then
		echo "==> $SOURCE_DIR already exists and is not a Git checkout, refusing to overwrite it."
		exit 1
	fi

	echo "==> Cloning claude-desktop-rpm..."
	mkdir -p "$(dirname "$SOURCE_DIR")"
	git clone "$REPO_URL" "$SOURCE_DIR"
fi

echo "==> Fetching Claude Desktop source via spectool..."
spectool -g -R "$SOURCE_DIR/claude-desktop.spec"

echo "==> Building the RPM..."
rpmbuild -bb "$SOURCE_DIR/claude-desktop.spec"

RPM_PATH=$(find "$HOME/rpmbuild/RPMS/$ARCH" -maxdepth 1 -name 'claude-desktop-*.rpm' -printf '%T@ %p\n' | sort -rn | head -n1 | cut -d' ' -f2-)
if [ -z "$RPM_PATH" ]; then
	echo "==> Build finished but no RPM found under $HOME/rpmbuild/RPMS/$ARCH."
	exit 1
fi

echo "==> Installing $RPM_PATH..."
sudo dnf install -y "$RPM_PATH"

echo "==> Done. Launch Claude Desktop from your app launcher."
