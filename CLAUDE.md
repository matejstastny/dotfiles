## Repo layout

- `configs/` - one subdir per app; `bin/link` symlinks each to `~/.config/<name>` by default
- `bin/` - scripts; this directory is in `$PATH` via `.zshrc`, so anything dropped here is immediately available as a command
- `rofi/` - rofi launcher scripts
- `install/` - random install scripts I might need for things not installed only through dnf, make a new one for each thing (do not append to existing ones unless specifically asked)
- `assets/` - fonts, screenshots, misc static files for repo and system

## Link system

`bin/link` (run after adding any new config):

- Default: `configs/<name>` → `~/.config/<name>` (symlinks the whole dir)
- `link.conf [path_overrides]`: symlinks the whole dir to a custom path
- `link.conf [file_overrides]`: symlinks individual files inside the dir to a custom target dir
- `bin/link --dry-run` to preview without touching anything

## Script style

- No file-level comments or docstrings. A single shebang line is enough.
- Notifications follow: `notify-send -t <ms> "✦ <topic>" "<message>"`
- Rofi pickers use: `rofi -dmenu -p "✦ <name> ✦"`

## Path conventions

- All directory paths in scripts must be **lowercase** - e.g. `~/videos/recordings`, not `~/Videos/Recordings`

## Blacklisted features

Do not suggest or add these - they have been deliberately rejected:

- **atuin** - vanilla shell history is preferred
- **color-switcher** - singular perfected theme
- **hyprland shadows** - perf heavy
- **cava** - no ingegrations, cava is done

## Notes

When asking for suggestions on what to add, do not be afraid of changing worfkflows, changing programs or refactoring things.

## Already implemented

Do not suggest these as new ideas - they're already in place:

- **Pretty boot pipeline** - `install/boot.sh` sets up Plymouth (motion theme), greetd autologin straight into Hyprland, and a purple-accented vimix GRUB theme, so boot goes GRUB → Plymouth splash → lockscreen seamlessly.
