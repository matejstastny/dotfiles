# quickshell

my desktop shell, written in qml. bar, panels, menus, pickers, lock screen
integration, wallpaper browser, notifications, media controls, and the small
things around them all live here.

- `shell.qml` is the entry point and ipc surface.
- `surface/` owns one shell surface per monitor: the screen outline, the bar
  that forms its top side, the toast stack and the drawers that slide out of it.
- `bar/`, `panel/`, and `osd/` are the always-visible pieces.
- `launcher/`, `pickers/`, `wifi/`, `bluetooth/`, and `cursor/` are command
  surfaces. they all share one drawer in `surface/`, so whichever keybind you
  hit, the answer is pulled out of the same edge of the outline.
  `powermenu/` and `wallpaper/` are drawers of their own.
- `common/` is the shared visual language. `Theme.qml` is the only place sizes,
  colours, spacing and motion are defined - no call site picks its own.

a command surface is a `CommandPicker`: data only, no window and no geometry.
it hands the drawer a `body` to build - by default a `CommandList` (prompt,
fuzzy filter, keyboard navigation) of `CommandRow`s. the picker objects live in
`shell.qml` so their models and processes exist once; only the body is
instantiated, on whichever monitor the surface opened on.

the blob field has a fixed number of slots (`BlobGroup.slotCount`) because qt
cannot bind a uniform array from qml. adding a shape means widening that, the
`vec4` block in `shaders/blob.frag`, and `SLOTS` with it.

the shaders under `shaders/` are checked in pre-compiled. rebuild them with
`./shaders/build.sh` after editing a `.vert` or `.frag`.

it is linked to `~/.config/quickshell` by `bin/link`. quickshell itself is
installed with `install/quickshell.sh`.
