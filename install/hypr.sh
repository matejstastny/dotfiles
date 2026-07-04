#!/usr/bin/env bash
set -euo pipefail

# Hyprland install script for Asahi Fedora (aarch64)

exec > >(tee -a "$HOME/out.log") 2>&1

echo "==> Updating system..."
sudo dnf update -y

echo "==> Enabling solopasha/hyprland COPR..."
sudo dnf copr enable -y solopasha/hyprland

# The COPR's aquamarine needs libdisplay-info.so.2, but aarch64 Fedora repos
# ship libdisplay-info 0.3.x (.so.3). Build 0.2.0 from source and package it
# under a compat name so it doesn't conflict with the official 0.3.x package.
if ! rpm -q compat-libdisplay-info-abi2 &>/dev/null; then
    echo "==> Building libdisplay-info 0.2.0 compat RPM (aarch64/DNF workaround)..."
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

    # Package only the runtime .so.2 files — no headers/pkgconfig/tools — so
    # this compat package can coexist with the official libdisplay-info 0.3.x.
    cat > "$RPMTOP/SPECS/compat-libdisplay-info-abi2.spec" << EOF
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

echo "==> Installing Hypr ecosystem (COPR)..."
sudo dnf install -y \
    hyprlock \
    hyprpaper \
    hypridle \
    hyprpicker \
    hyprwayland-scanner \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk

echo "==> Installing Hyprland build dependencies..."
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
    pugixml-devel readline-devel

# hwdata ships its .pc in /usr/share/pkgconfig which cmake doesn't always search
export PKG_CONFIG_PATH="/usr/share/pkgconfig:/usr/lib64/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

# Fedora's hwdata package has no .pc file — create one so aquamarine finds it
if ! pkg-config --exists hwdata 2>/dev/null; then
    HWDATA_VER=$(rpm -q hwdata --queryformat '%{VERSION}')
    sudo tee /usr/lib64/pkgconfig/hwdata.pc > /dev/null << EOF
prefix=/usr
datadir=/usr/share/hwdata

Name: hwdata
Description: Hardware Database
Version: ${HWDATA_VER}
Datadir=\${datadir}
EOF
fi

# COPR has hyprlang 0.6.4 but hyprland 0.55 needs >= 0.6.7 — build from source
build_hypr_lib() {
    local repo="$1" tmpdir
    tmpdir=$(mktemp -d)
    git clone --depth 1 "https://github.com/hyprwm/${repo}.git" "$tmpdir"
    cmake -S "$tmpdir" -B "$tmpdir/build" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=/usr/lib64
    cmake --build "$tmpdir/build" -j$(nproc)
    sudo cmake --install "$tmpdir/build"
    sudo ldconfig
    rm -rf "$tmpdir"
}

echo "==> Building hyprlang from source..."
build_hypr_lib hyprlang

echo "==> Building hyprwire from source..."
build_hypr_lib hyprwire

echo "==> Building hyprutils from source..."
build_hypr_lib hyprutils

echo "==> Building hyprgraphics from source..."
build_hypr_lib hyprgraphics

echo "==> Building hyprcursor from source..."
build_hypr_lib hyprcursor

echo "==> Building aquamarine from source..."
build_hypr_lib aquamarine

echo "==> Building Hyprland latest from source (Lua support)..."
HLDIR=$(mktemp -d)
git clone --recurse-submodules --depth 1 \
    https://github.com/hyprwm/Hyprland.git "$HLDIR"
cmake -S "$HLDIR" -B "$HLDIR/build" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_INSTALL_LIBDIR=/usr/lib64
cmake --build "$HLDIR/build" -j$(nproc)
sudo cmake --install "$HLDIR/build"
rm -rf "$HLDIR"

echo "==> Installing Wayland utilities..."
sudo dnf install -y \
    waybar \
    wofi \
    mako \
    foot \
    grim \
    slurp \
    wl-clipboard \
    brightnessctl \
    playerctl \
    swww \
    cliphist

echo "==> Installing audio (PipeWire)..."
sudo dnf install -y \
    pipewire \
    pipewire-pulseaudio \
    wireplumber \
    pavucontrol \
    sound-theme-freedesktop

echo "==> Installing system integration..."
sudo dnf install -y \
    polkit \
    lxqt-policykit \
    gnome-keyring \
    network-manager-applet \
    blueman \
    thunar

echo "==> Installing fonts..."
sudo dnf install -y \
    jetbrains-mono-fonts \
    fontawesome-fonts \
    google-noto-emoji-fonts

echo "==> Enabling PipeWire user services..."
systemctl --user enable --now pipewire pipewire-pulse wireplumber || true

echo ""
echo "Done! To start Hyprland:"
echo "  - Select 'Hyprland' from your display manager login screen, or"
echo "  - Add 'exec Hyprland' to ~/.bash_profile / ~/.zprofile for TTY login"
echo ""
echo "Default config will be at ~/.config/hypr/hyprland.conf on first launch."
