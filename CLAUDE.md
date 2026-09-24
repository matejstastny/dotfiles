## repo layout

- `configs/` - one subdir per app; `bin/link` symlinks each to `~/.config/<name>` by default
- `bin/` - terminal commands; this directory is in `$PATH` via `.zshrc`
- `scripts/` - internal executables for Quickshell, Hyprland, and services; use file extensions here
- `rofi/` - rofi launcher scripts
- `install/` - random install scripts I might need for things not installed only through dnf, make a new one for each thing (do not append to existing ones unless specifically asked)
- `assets/` - fonts, screenshots, misc static files for repo and system

## link system

`bin/link` (run after adding any new config):

- Default: `configs/<name>` → `~/.config/<name>` (symlinks the whole dir)
- `link.conf [path_overrides]`: symlinks the whole dir to a custom path
- `link.conf [file_overrides]`: symlinks individual files inside the dir to a custom target dir
- `bin/link --dry-run` to preview without touching anything

## script style

- No file-level comments or docstrings. A single shebang line is enough.
- Notifications follow: `notify-send -t <ms> "✦ <topic>" "<message>"`

## path conventions

- All directory paths in scripts must be **lowercase** - e.g. `~/videos/recordings`, not `~/Videos/Recordings`

## notes

When asking for suggestions on what to add, do not be afraid of changing worfkflows, changing programs or refactoring things.
Do not commit in this repo. I will do that always
