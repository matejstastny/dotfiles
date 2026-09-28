# quickshell

my desktop shell, written in qml. bar, panels, menus, pickers, lock screen
integration, wallpaper browser, notifications, media controls, and the small
things around them all live here.

- `shell.qml` is the entry point and ipc surface.
- `surface/` owns one shell surface per monitor.
- `bar/`, `panel/`, and `osd/` are the always-visible pieces.
- `launcher/`, `pickers/`, `wifi/`, `bluetooth/`, `cursor/`, and `powermenu/`
  are popouts.
- `common/` is the shared visual language.

it is linked to `~/.config/quickshell` by `bin/link`. quickshell itself is
installed with `install/quickshell.sh`.
