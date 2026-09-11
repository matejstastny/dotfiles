#!/usr/bin/env bash
set -euo pipefail
#@ custom "nyx" grub theme, hand-built to match the quickshell purple palette

echo ""
echo "✦ ✧ ✦  GRUB: nyx theme"
echo ""

echo "✦ Installing grub2-tools-extra (grub2-mkfont)..."
sudo dnf install -y grub2-tools-extra

RESOLUTION="2560x1664"
THEME_DIR="/boot/grub2/themes/nyx"
FONT_TTF="$HOME/.local/share/fonts/MapleMono/MapleMono-NF-Regular.ttf"
FONT_BOLD_TTF="$HOME/.local/share/fonts/MapleMono/MapleMono-NF-Bold.ttf"

BASE="#0d0d14"
SURFACE="#181825"
PURPLE="#7878c8"
BRIGHT="#f0f0ff"
DIM="#9898c0"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo ""
echo "✦ Rendering background (gradient + stars)..."
magick -size "$RESOLUTION" radial-gradient:"$SURFACE"-"$BASE" "$TMP/bg-base.png"

W=${RESOLUTION%x*}
H=${RESOLUTION#*x}
star_args=()
for _ in $(seq 1 70); do
	x=$((RANDOM % W))
	y=$((RANDOM % (H * 70 / 100)))
	r=$(((RANDOM % 2) + 1))
	op=$(awk -v s="$RANDOM" 'BEGIN { srand(s); printf "%.2f", 0.15 + rand() * 0.35 }')
	star_args+=(-fill "rgba(255,255,255,$op)" -draw "circle $x,$y $((x + r)),$y")
done
magick -size "$RESOLUTION" xc:none "${star_args[@]}" "$TMP/bg-stars.png"
magick "$TMP/bg-stars.png" -blur 0x1 "$TMP/bg-stars.png"
magick "$TMP/bg-base.png" "$TMP/bg-stars.png" -compose over -composite "$TMP/background.png"

echo ""
echo "✦ Building fonts from Maple Mono NF..."
grub2-mkfont --output="$TMP/nyx-24.pf2" --size=24 --name="NyxMono" "$FONT_BOLD_TTF"
grub2-mkfont --output="$TMP/nyx-20.pf2" --size=20 --name="NyxMono" "$FONT_TTF"
grub2-mkfont --output="$TMP/nyx-14.pf2" --size=14 --name="NyxMono" "$FONT_TTF"

cat >"$TMP/theme.txt" <<THEME
# GRUB2 gfxmenu theme - nyx (hand-built, matches the quickshell purple palette)

title-text: ""
desktop-image: "background.png"
desktop-color: "$BASE"
terminal-font: "NyxMono 14"
terminal-width: "100%"
terminal-height: "100%"
terminal-border: "0"

+ label {
  top = 14%
  left = 0%
  width = 100%
  align = "center"
  text = "✦ select an os ✦"
  color = "$PURPLE"
  font = "NyxMono 24"
}

+ boot_menu {
  left = 32%
  top = 34%
  width = 36%
  height = 32%
  item_font = "NyxMono 20"
  item_color = "$DIM"
  selected_item_font = "NyxMono 20"
  selected_item_color = "$BRIGHT"
  icon_width = 0
  icon_height = 0
  item_height = 42
  item_padding = 10
  item_spacing = 16
  item_icon_space = 0
}

+ label {
  top = 88%
  left = 0%
  width = 100%
  align = "center"
  id = "__timeout__"
  text = "booting in %d seconds"
  color = "$DIM"
  font = "NyxMono 14"
}
THEME

echo ""
if [ -d /boot/grub2/themes/vimix ]; then
	echo "✦ Removing old vimix theme..."
	sudo rm -rf /boot/grub2/themes/vimix
fi

echo "✦ Installing nyx theme to $THEME_DIR..."
sudo rm -rf "$THEME_DIR"
sudo mkdir -p "$THEME_DIR"
sudo cp "$TMP/background.png" "$TMP"/nyx-*.pf2 "$TMP/theme.txt" "$THEME_DIR/"

echo ""
echo "✦ Pointing /etc/default/grub at the nyx theme..."
if grep -q "^GRUB_THEME=" /etc/default/grub; then
	sudo sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"$THEME_DIR/theme.txt\"|" /etc/default/grub
else
	echo "GRUB_THEME=\"$THEME_DIR/theme.txt\"" | sudo tee -a /etc/default/grub >/dev/null
fi

echo ""
echo "✦ Regenerating grub.cfg..."
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

echo ""
echo "✦ ✧ ✦  Done! Reboot to see it."
echo ""
