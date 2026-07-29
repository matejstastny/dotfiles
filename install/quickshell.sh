#!/usr/bin/env bash
set -euo pipefail

log() {
	echo -e "\033[35m==> $*\033[0m"
}

exec > >(tee -a "$HOME/quickshell-install.log") 2>&1

log "Quickshell source installer"
log "The errornointernet/quickshell COPR only has 0.3.0 built against Qt 6.11,"
log "but hyprland-qt-support (needed by hyprpolkitagent/hyprsysteminfo) is still"
log "built against Qt 6.10's private ABI, so that RPM can't install cleanly."
log "Building locally against the Qt 6.10 already on this system sidesteps the"
log "conflict entirely - quickshell itself only needs Qt >= 6.6."

QS_VERSION="0.3.0"

# Pinned to whatever Qt 6.10.x is currently installed so dnf doesn't pull in
# qt6-qtbase 6.11 as a side effect - that's the whole point of building
# locally instead of using the COPR RPM. If you've since moved to Qt 6.11
# system-wide, just use the COPR package instead of this script.
QT_BASE_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}' qt6-qtbase)
QT_WAYLAND_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}' qt6-qtwayland)

log "Enabling errornointernet/quickshell COPR (for cpptrace-devel)..."
sudo dnf copr enable -y errornointernet/quickshell

log "Installing build dependencies, pinned to installed Qt ${QT_BASE_VERSION}..."
sudo dnf install -y \
	"qt6-qtbase-devel-${QT_BASE_VERSION}" \
	"qt6-qtbase-private-devel-${QT_BASE_VERSION}" \
	"qt6-qtdeclarative-devel-${QT_BASE_VERSION}" \
	"qt6-qtshadertools-devel-${QT_BASE_VERSION}" \
	"qt6-qtwayland-devel-${QT_WAYLAND_VERSION}" \
	cmake gcc-c++ ninja-build \
	cpptrace-devel \
	vulkan-headers \
	cli11-devel \
	mesa-libgbm-devel \
	glib2-devel \
	jemalloc-devel \
	libdrm-devel \
	pipewire-devel \
	libzstd-devel \
	pam-devel \
	polkit-devel \
	wayland-devel \
	wayland-protocols-devel \
	spirv-tools

if rpm -q quickshell &>/dev/null; then
	log "Removing RPM-packaged quickshell so the local build owns /usr/bin/quickshell..."
	sudo dnf remove -y quickshell
fi

log "Cloning quickshell v${QS_VERSION}..."
BUILDDIR=$(mktemp -d)
git clone --depth 1 --branch "v${QS_VERSION}" \
	https://github.com/quickshell-mirror/quickshell.git \
	"$BUILDDIR/src"

log "Configuring..."
cmake -S "$BUILDDIR/src" -B "$BUILDDIR/build" -GNinja \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=/usr \
	-DBUILD_SHARED_LIBS=OFF \
	-DINSTALL_QML_PREFIX=lib64/qt6/qml \
	-DDISTRIBUTOR="dotfiles (local build)"

log "Building..."
cmake --build "$BUILDDIR/build"

log "Installing to /usr..."
sudo cmake --install "$BUILDDIR/build"

rm -rf "$BUILDDIR"

log "Done. Verify with: quickshell --version"
