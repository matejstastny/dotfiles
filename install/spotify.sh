#!/usr/bin/env bash
set -euo pipefail

VERSION_FILE="/usr/share/spotify/.dotfiles-version"
FEX_ROOTFS_DIR="/usr/share/fex-emu/RootFS/fedora-with-extras"
FEX_ROOTFS_MARKER="$FEX_ROOTFS_DIR/.dotfiles-source-version"
FEX_GLOBAL_CONFIG="/usr/share/fex-emu/Config.json"

# Apple Silicon hosts run a 16k page-size kernel, but jemalloc (bundled in
# Spotify's libcef) is hardcoded for 4k pages and aborts on raw FEX. It only
# works wrapped in muvm's 4k microVM, which binfmt-dispatcher (not fex-emu
# alone) is what wires up.
if ! rpm -q binfmt-dispatcher &>/dev/null; then
	echo "✦ Installing binfmt-dispatcher (routes FEX through muvm on 16k-page hosts)..."
	sudo dnf install -y binfmt-dispatcher
	sudo systemctl restart systemd-binfmt.service
fi

# Cleanup from an earlier version of this script: per-app AppConfig doesn't
# work once FEXServer is involved (see below), so this never did anything.
if [ -e /usr/share/fex-emu/AppConfig/spotify.json ] || [ -e /usr/share/fex-emu/RootFS/fedora-spotify ]; then
	sudo rm -f /usr/share/fex-emu/AppConfig/spotify.json
	sudo rm -rf /usr/share/fex-emu/RootFS/fedora-spotify
fi

# The Fedora FEX rootfs is missing Spotify's tray-icon deps. All x86_64 apps
# share a single FEXServer-managed rootfs mount (it mounts once per session
# from the ROOTFS config value and hands that same mount to every client -
# there's no per-app override once FEXServer is involved, and per-app
# AppConfig / a $HOME overlay are both ignored for this reason). So instead
# of an overlay, we extract the base image once, add the missing libs, and
# repoint the *global* FEX RootFS config at the merged copy - it's additive
# only, so this is safe for every other app that runs under FEX too.
ROOTFS_SOURCE_VERSION=$(rpm -q --qf '%{VERSION}-%{RELEASE}' fex-emu-rootfs-fedora)
CURRENT_MARKER=""
[ -f "$FEX_ROOTFS_MARKER" ] && CURRENT_MARKER=$(cat "$FEX_ROOTFS_MARKER")

if [ "$CURRENT_MARKER" != "$ROOTFS_SOURCE_VERSION" ]; then
	echo "✦ Building a FEX rootfs with tray-icon libs added (base: $ROOTFS_SOURCE_VERSION)..."
	TMP=$(mktemp -d)
	sudo fsck.erofs --extract="$TMP/root" /usr/share/fex-emu/RootFS/default.erofs

	dnf download --forcearch=x86_64 --arch=x86_64 --destdir="$TMP" \
		libayatana-appindicator-gtk3 libayatana-indicator-gtk3 libayatana-ido-gtk3 \
		libdbusmenu libdbusmenu-gtk3
	mkdir -p "$TMP/extract"
	for rpm in "$TMP"/*.rpm; do
		rpm2cpio "$rpm" | (cd "$TMP/extract" && cpio -idm --quiet)
	done
	sudo cp -a "$TMP/extract"/usr/lib64/lib{ayatana,dbusmenu}*.so* "$TMP/root/usr/lib64/"
	echo "$ROOTFS_SOURCE_VERSION" | sudo tee "$TMP/root/.dotfiles-source-version" >/dev/null

	sudo rm -rf "$FEX_ROOTFS_DIR"
	sudo mkdir -p "$(dirname "$FEX_ROOTFS_DIR")"
	sudo mv "$TMP/root" "$FEX_ROOTFS_DIR"
	sudo rm -rf "$TMP"
fi

if ! grep -q "$FEX_ROOTFS_DIR" "$FEX_GLOBAL_CONFIG" 2>/dev/null; then
	echo "✦ Pointing FEX's global RootFS config at the merged rootfs..."
	sudo tee "$FEX_GLOBAL_CONFIG" >/dev/null <<EOF
{
  "Config": {
    "RootFS": "$FEX_ROOTFS_DIR"
  }
}
EOF
	echo "✦ Restarting FEXServer so it picks up the new rootfs..."
	FEXServer -k 2>/dev/null || true
fi

echo "✦ Fetching latest Spotify version (x86_64 .deb, runs via FEX)..."
PACKAGES=$(curl -fsSL http://repository.spotify.com/dists/stable/non-free/binary-amd64/Packages)
FILENAME=$(echo "$PACKAGES" | awk '/^Package: spotify-client$/{f=1} f && /^Filename:/{print $2; exit}')
LATEST_VERSION=$(echo "$PACKAGES" | awk '/^Package: spotify-client$/{f=1} f && /^Version:/{print $2; exit}')

INSTALLED_VERSION=""
[ -f "$VERSION_FILE" ] && INSTALLED_VERSION=$(cat "$VERSION_FILE")

if [ "$INSTALLED_VERSION" = "$LATEST_VERSION" ]; then
	echo "✦ Spotify $LATEST_VERSION already installed, skipping download"
else
	if [ -n "$INSTALLED_VERSION" ]; then
		echo "✦ Updating Spotify $INSTALLED_VERSION -> $LATEST_VERSION..."
	else
		echo "✦ Installing Spotify $LATEST_VERSION..."
	fi

	TMP=$(mktemp -d)
	curl -fsSL "http://repository.spotify.com/$FILENAME" -o "$TMP/spotify-client.deb"
	(cd "$TMP" && ar x spotify-client.deb)
	mkdir -p "$TMP/root"
	tar -xf "$TMP"/data.tar.* -C "$TMP/root"

	sudo cp -a "$TMP/root/usr/." /usr/
	echo "$LATEST_VERSION" | sudo tee "$VERSION_FILE" >/dev/null

	rm -rf "$TMP"
fi

# The .deb's postinst normally runs xdg-desktop-menu/xdg-icon-resource to do
# this; we skip postinst (no dpkg), so do it ourselves every run - cheap and
# self-heals a launcher entry that's missing or stale.
echo "✦ Installing icons..."
for icon in /usr/share/spotify/icons/spotify-linux-*.png; do
	size=$(basename "$icon" .png)
	size=${size#spotify-linux-}
	sudo mkdir -p "/usr/share/icons/hicolor/${size}x${size}/apps"
	sudo cp "$icon" "/usr/share/icons/hicolor/${size}x${size}/apps/spotify.png"
done
command -v gtk-update-icon-cache &>/dev/null && sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true

echo "✦ Installing desktop entry..."
sudo tee /usr/share/applications/spotify.desktop >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Spotify
GenericName=Music Player
Icon=spotify
TryExec=spotify
Exec=spotify %U
Terminal=false
MimeType=x-scheme-handler/spotify;
Categories=Audio;Music;Player;AudioVideo;
StartupWMClass=spotify
EOF

command -v update-desktop-database &>/dev/null && sudo update-desktop-database "/usr/share/applications" 2>/dev/null || true

echo ""
echo "✦ Done. Spotify $LATEST_VERSION installed."
echo "  Launch: spotify"
