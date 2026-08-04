#!/usr/bin/env bash
set -euo pipefail

log() {
	echo -e "\033[35m==> $*\033[0m"
}

exec > >(tee -a "$HOME/hypr-install.log") 2>&1

log "Asahi Fedora Linux Hyprland installer"
log "Depency issues might occur. This script installs deps for version 0.56.0"
log "Updating system..."
sudo dnf update -y

log "Enabling solopasha/hyprland COPR..."
sudo dnf copr enable -y solopasha/hyprland

# The COPR's aquamarine needs libdisplay-info.so.2, but aarch64 Fedora repos
# ship libdisplay-info 0.3.x (.so.3). Build 0.2.0 from source and package it
# under a compat name so it doesn't conflict with the official 0.3.x package
if ! rpm -q compat-libdisplay-info-abi2 &>/dev/null; then
	log "Building libdisplay-info 0.2.0 compat RPM..."
	sudo dnf install -y git meson ninja-build hwdata gcc pkg-config rpm-build

	BUILDDIR=$(mktemp -d)
	STAGING="$BUILDDIR/staging"
	RPMTOP="$BUILDDIR/rpmbuild"
	mkdir -p "$RPMTOP"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

	git clone --depth 1 --branch 0.2.0 \
		https://gitlab.freedesktop.org/emersion/libdisplay-info.git \
		"$BUILDDIR/src"
	meson setup "$BUILDDIR/src" "$BUILDDIR/build" --prefix=/usr --libdir=/usr/lib64
	ninja -C "$BUILDDIR/build"
	DESTDIR="$STAGING" ninja -C "$BUILDDIR/build" install

	# Package only the runtime .so.2 files - no headers/pkgconfig/tools - so
	# this compat package can coexist with the official libdisplay-info 0.3.x.
	cat >"$RPMTOP/SPECS/compat-libdisplay-info-abi2.spec" <<EOF
Name:           compat-libdisplay-info-abi2
Version:        0.2.0
Release:        1
Summary:        libdisplay-info ABI 2 runtime compat library
License:        MIT
BuildArch:      aarch64

%description
Provides libdisplay-info.so.2 for packages built against libdisplay-info 0.2.x.
Coexists with the official libdisplay-info 0.3.x package.

%install
mkdir -p %{buildroot}%{_libdir}
cp "${STAGING}/usr/lib64/libdisplay-info.so.0.2.0" %{buildroot}%{_libdir}/
ln -s libdisplay-info.so.0.2.0 %{buildroot}%{_libdir}/libdisplay-info.so.2

%post -p /sbin/ldconfig
%postun -p /sbin/ldconfig

%files
%{_libdir}/libdisplay-info.so.0.2.0
%{_libdir}/libdisplay-info.so.2
EOF

	rpmbuild --define "_topdir $RPMTOP" -bb "$RPMTOP/SPECS/compat-libdisplay-info-abi2.spec"
	sudo rpm -ivh "$RPMTOP/RPMS/aarch64/compat-libdisplay-info-abi2-0.2.0-1.aarch64.rpm"
	sudo ldconfig
	rm -rf "$BUILDDIR"
fi

log "Installing hypr ecosystem from copr..."
sudo dnf install -y \
	hyprlock \
	hyprpaper \
	hypridle \
	hyprpicker \
	hyprwayland-scanner \
	xdg-desktop-portal-hyprland \
	xdg-desktop-portal-gtk

log "Installing hyprland build dependencies..."
sudo dnf install -y \
	cmake gcc-c++ ninja-build \
	wayland-devel wayland-protocols-devel \
	libdrm-devel libinput-devel \
	pixman-devel cairo-devel pango-devel \
	libxkbcommon-devel mesa-libEGL-devel mesa-libgbm-devel \
	libseat-devel systemd-devel \
	xcb-util-wm-devel xcb-util-errors-devel \
	xcb-util-renderutil-devel libXcursor-devel \
	glslang-devel lua-devel \
	libjpeg-turbo-devel libwebp-devel file-devel librsvg2-devel \
	libzip-devel tomlplusplus-devel \
	libdisplay-info-devel \
	re2-devel muParser-devel \
	pugixml-devel readline-devel \
	libeis-devel sdbus-cpp-devel

# hwdata ships its .pc in /usr/share/pkgconfig which cmake doesn't always search
export PKG_CONFIG_PATH="/usr/share/pkgconfig:/usr/lib64/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

# Fedora's hwdata package has no .pc file - create one so aquamarine finds it
if ! pkg-config --exists hwdata 2>/dev/null; then
	HWDATA_VER=$(rpm -q hwdata --queryformat '%{VERSION}')
	sudo tee /usr/lib64/pkgconfig/hwdata.pc >/dev/null <<EOF
prefix=/usr
datadir=/usr/share/hwdata

Name: hwdata
Description: Hardware Database
Version: ${HWDATA_VER}
Datadir=\${datadir}
EOF
fi

# Versions below are pinned to exactly what Hyprland's own flake.lock uses
# for HYPRLAND_TAG - i.e. the combination the maintainers actually built and
# tested together. Don't bump individual libs to "latest" independently of
# Hyprland - that's what caused a whole debugging saga once already.
# To upgrade: bump HYPRLAND_TAG, then re-derive these from
# https://raw.githubusercontent.com/hyprwm/Hyprland/<tag>/flake.lock
HYPRLAND_TAG="v0.56.1"
HYPRUTILS_REF="v0.14.0"
HYPRLANG_REF="090117506ddc3d7f26e650ff344d378c2ec329cc"
HYPRCURSOR_REF="39435900785d0c560c6ae8777d29f28617d031ef"
HYPRGRAPHICS_REF="c6e7b9f673f4360bc813d3dc75028f75ee88d3f8"
AQUAMARINE_REF="v0.13.0"
HYPRWIRE_REF="85148a8e612808cf5ddb25d0b3c5840f3498a7dc"

# COPR has hyprlang 0.6.4 but hyprland 0.55 needs >= 0.6.7 - build from source
build_hypr_lib() {
	local repo="$1" ref="$2" tmpdir
	tmpdir=$(mktemp -d)
	git -C "$tmpdir" init -q
	git -C "$tmpdir" remote add origin "https://github.com/hyprwm/${repo}.git"
	git -C "$tmpdir" fetch --depth 1 origin "$ref"
	git -C "$tmpdir" checkout -q FETCH_HEAD
	cmake -S "$tmpdir" -B "$tmpdir/build" \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_INSTALL_LIBDIR=/usr/lib64
	cmake --build "$tmpdir/build" -j$(nproc)
	sudo cmake --install "$tmpdir/build"
	sudo ldconfig
	rm -rf "$tmpdir"
}

read -rp "Install Hyprland ${HYPRLAND_TAG} + pinned deps from source? [y/N] " hl_confirm
if [[ "$hl_confirm" =~ ^[Yy]$ ]]; then
	log "Building hyprlang (${HYPRLANG_REF}) from source..."
	build_hypr_lib hyprlang "$HYPRLANG_REF"

	log "Building hyprwire (${HYPRWIRE_REF}) from source..."
	build_hypr_lib hyprwire "$HYPRWIRE_REF"

	log "Building hyprutils (${HYPRUTILS_REF}) from source..."
	build_hypr_lib hyprutils "$HYPRUTILS_REF"

	log "Building hyprgraphics (${HYPRGRAPHICS_REF}) from source..."
	build_hypr_lib hyprgraphics "$HYPRGRAPHICS_REF"

	log "Building hyprcursor (${HYPRCURSOR_REF}) from source..."
	build_hypr_lib hyprcursor "$HYPRCURSOR_REF"

	log "Building aquamarine (${AQUAMARINE_REF}) from source..."
	build_hypr_lib aquamarine "$AQUAMARINE_REF"

	log "Building Hyprland ${HYPRLAND_TAG} from source (Lua support)..."
	HLDIR=$(mktemp -d)
	git clone --recurse-submodules --depth 1 --branch "$HYPRLAND_TAG" \
		https://github.com/hyprwm/Hyprland.git "$HLDIR"
	cmake -S "$HLDIR" -B "$HLDIR/build" \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_INSTALL_LIBDIR=/usr/lib64
	cmake --build "$HLDIR/build" -j$(nproc)
	sudo cmake --install "$HLDIR/build"
	rm -rf "$HLDIR"
else
	log "Skipping Hyprland source build."
fi

log "Installing Wayland utilities..."
sudo dnf install -y \
	kitty \
	rofi \
	grim \
	slurp \
	wl-clipboard \
	brightnessctl \
	playerctl \
	swww \
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
