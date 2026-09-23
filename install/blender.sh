#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://projects.blender.org/blender/blender.git"
SOURCE_DIR="$HOME/source/blender"
BUILD_DIR="$HOME/source/build_linux"

if ! command -v dnf >/dev/null; then
	echo "This installer currently supports Fedora and other dnf-based distributions."
	exit 1
fi

echo "==> Installing Blender build prerequisites..."
sudo dnf install -y python3.13-devel git git-lfs

if [ -d "$SOURCE_DIR/.git" ]; then
	ORIGIN_URL=$(git -C "$SOURCE_DIR" remote get-url origin 2>/dev/null || true)
	if [ "$ORIGIN_URL" != "$REPO_URL" ]; then
		echo "==> $SOURCE_DIR is not a Blender checkout, refusing to overwrite it."
		exit 1
	fi

	if ! git -C "$SOURCE_DIR" diff --quiet || ! git -C "$SOURCE_DIR" diff --cached --quiet; then
		echo "==> $SOURCE_DIR has local changes, refusing to update it."
		exit 1
	fi

	echo "==> Updating Blender source..."
	git -C "$SOURCE_DIR" pull --ff-only
else
	if [ -e "$SOURCE_DIR" ]; then
		echo "==> $SOURCE_DIR already exists and is not a Git checkout, refusing to overwrite it."
		exit 1
	fi

	echo "==> Cloning Blender into $SOURCE_DIR..."
	mkdir -p "$(dirname "$SOURCE_DIR")"
	git clone "$REPO_URL" "$SOURCE_DIR"
fi

(cd "$SOURCE_DIR" && git lfs install --local --force)

echo "==> Installing system build dependencies..."
(cd "$SOURCE_DIR" && ./build_files/linux/install_linux_packages.py)

# blender helper missing deps
sudo dnf install -y \
	ffmpeg-devel \
	fftw-devel \
	fmt-devel \
	libshaderc-devel \
	libsndfile-devel \
	libspnav-devel \
	openal-soft-devel \
	openexr-devel \
	OpenImageIO-devel \
	OpenImageIO-plugin-osl \
	openshadinglanguage \
	openshadinglanguage-devel \
	openvdb-devel \
	sse2neon-devel

echo "==> Updating Blender modules..."
(cd "$SOURCE_DIR" && make update_code)

echo "==> Building Blender for $(uname -m)..."
echo "    build output: $BUILD_DIR/bin/blender"
(cd "$SOURCE_DIR" && make ninja)

echo "==> Done. Run Blender with: $BUILD_DIR/bin/blender"
