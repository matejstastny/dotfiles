#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "✦ ✧ ✦  Boot: Plymouth · greetd · GRUB vimix"
echo ""

# Plymouth
echo "✦ Installing Plymouth..."
sudo dnf install -y plymouth plymouth-plugin-script plymouth-system-theme

echo ""
echo "✦ Installing Plymouth motion theme..."
if [ -d /usr/share/plymouth/themes/motion ]; then
	echo "  already installed, skipping"
else
	TMP=$(mktemp -d)
	git clone --depth=1 --filter=blob:none --sparse \
		https://github.com/adi1090x/plymouth-themes.git "$TMP/plymouth-themes"
	git -C "$TMP/plymouth-themes" sparse-checkout set pack_3/motion
	sudo cp -r "$TMP/plymouth-themes/pack_3/motion" /usr/share/plymouth/themes/
	rm -rf "$TMP"
	echo "  installed"
fi

echo ""
echo "✦ Setting Plymouth motion theme and rebuilding initrd..."
sudo plymouth-set-default-theme -R motion

# greetd
echo ""
echo "✦ Installing greetd..."
sudo dnf install -y greetd

echo ""
echo "✦ Configuring greetd autologin..."
sudo tee /etc/greetd/config.toml >/dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "agreety --cmd /bin/sh"
user = "greetd"

[initial_session]
command = "$HOME/dotfiles/bin/hyprland-session"
user = "$USER"
EOF

echo ""
echo "✦ Enabling greetd and setting graphical target..."
sudo systemctl enable greetd
sudo systemctl set-default graphical.target

echo ""
echo "✦ Removing agetty autologin override if present..."
AUTOLOGIN_CONF=/etc/systemd/system/getty@tty1.service.d/autologin.conf
if [ -f "$AUTOLOGIN_CONF" ]; then
	sudo rm "$AUTOLOGIN_CONF"
	sudo rmdir /etc/systemd/system/getty@tty1.service.d/ 2>/dev/null || true
	sudo systemctl daemon-reload
	echo "  removed"
else
	echo "  not present, skipping"
fi

# GRUB vimix theme
echo ""
echo "✦ Installing vimix GRUB theme..."

RESOLUTION="2560x1664"

if [ ! -d /boot/grub2/themes/vimix ]; then
	TMP=$(mktemp -d)
	git clone --depth=1 https://github.com/vinceliuice/grub2-themes.git "$TMP/grub2-themes"
	magick -size "$RESOLUTION" gradient:"#07000f-#0f0118" "$TMP/grub2-themes/background.jpg"
	sudo "$TMP/grub2-themes/install.sh" -t vimix -b -c "$RESOLUTION"
	rm -rf "$TMP"
	echo "  installed"
else
	echo "  already installed, skipping clone+install"
fi

echo ""
echo "✦ Applying purple color scheme..."

sudo magick /boot/grub2/themes/vimix/select_c.png \
	-fill "#9d79d6" -colorize 100 /boot/grub2/themes/vimix/select_c.png
sudo magick /boot/grub2/themes/vimix/select_e.png \
	-fill "#9d79d6" -colorize 100 /boot/grub2/themes/vimix/select_e.png
sudo magick /boot/grub2/themes/vimix/select_w.png \
	-fill "#9d79d6" -colorize 100 /boot/grub2/themes/vimix/select_w.png

sudo tee /boot/grub2/themes/vimix/theme.txt >/dev/null <<'THEME'
# GRUB2 gfxmenu Linux theme

# Global Property
title-text: ""
desktop-image: "background.jpg"
desktop-color: "#000000"
terminal-font: "Terminus Regular 18"
terminal-box: "terminal_box_*.png"
terminal-width: "100%"
terminal-height: "100%"
terminal-border: "0"

+ boot_menu {
  left = 30%
  top = 30%
  width = 40%
  height = 40%
  item_font = "Unifont Regular 32"
  item_color = "#9d79d6"
  selected_item_color = "#c9a8f5"
  icon_width = 64
  icon_height = 64
  item_icon_space = 36
  item_height = 80
  item_padding = 12
  item_spacing = 24
  selected_item_pixmap_style = "select_*.png"
}

+ label {
  top = 82%
  left = 32%
  width = 36%
  align = "center"
  id = "__timeout__"
  text = "Booting in %d seconds"
  color = "#9d79d6"
  font = "Unifont Regular 32"
}
THEME

# /etc/default/grub
echo ""
echo "✦ Updating /etc/default/grub..."

QUIET_FLAGS="quiet splash loglevel=3 rd.udev.log_level=3 vt.global_cursor_default=0 systemd.show_status=false"

if ! grep -q "quiet" /etc/default/grub; then
	sudo sed -i "s|\(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*\)\"|\1 $QUIET_FLAGS\"|" /etc/default/grub
	echo "  added quiet/splash flags"
else
	echo "  quiet flags already present, skipping"
fi

if ! grep -q "^GRUB_GFXMODE=$RESOLUTION" /etc/default/grub; then
	if grep -q "^GRUB_GFXMODE=" /etc/default/grub; then
		sudo sed -i "s|^GRUB_GFXMODE=.*|GRUB_GFXMODE=$RESOLUTION,auto|" /etc/default/grub
	else
		echo "GRUB_GFXMODE=$RESOLUTION,auto" | sudo tee -a /etc/default/grub >/dev/null
	fi
	echo "  set GRUB_GFXMODE=$RESOLUTION"
fi

echo ""
echo "✦ Regenerating grub.cfg..."
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

echo ""
echo "✦ ✧ ✦  Done! Reboot to apply."
echo ""
