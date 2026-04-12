# dotfiles — Claude Code guide

## dot script

`bin/dot` is the dotfiles task manager. It symlinks configs, manages Homebrew packages, and installs assets (fonts, wallpaper).

```
dot link       Symlink configs to system locations
dot brew       Install/update Homebrew packages
dot assets     Install fonts and set wallpaper
dot update     Run brew + link
dot all        Run all tasks (link, brew, assets)
dot check      Show symlink status for all configs
dot diff       Show Brewfile vs installed packages
```

## Adding a new config

1. Create a folder under `configs/<name>/` and add your config files inside it.
2. By default, `dot link` will symlink the **whole folder** to `~/.config/<name>`.
3. If the config needs to land somewhere else, add an entry to `link.toml` under the appropriate section:

```toml
[directories]
# Symlink the whole folder to a custom path instead of ~/.config/<name>
# name = "symlink_path"

[files]
# Link each file inside configs/<name>/ individually into the target directory
# name = "target_directory"
```

**Examples from `link.toml`:**
- `[files]` `zsh = "$HOME"` — each file in `configs/zsh/` is linked into `~` (so `.zshrc` → `~/.zshrc`)
- `[files]` `vscode = "$HOME/Library/Application Support/Code/User"` — each file linked into the VS Code user dir
- `[files]` `claude = "$HOME/.claude"` — each file linked into `~/.claude`
- `[directories]` entries symlink the whole folder to a custom path (e.g. a non-`~/.config` location)
- Configs *not* in `link.toml` (e.g. `ghostty`, `nvim`) get their folder linked to `~/.config/<name>`

After adding the folder (and optionally `link.toml` entry), run `dot link` to apply.

## Adding a Homebrew package

Add a line to `Brewfile`:

```ruby
brew "package-name"        # formula
cask "app-name"            # cask (GUI app)
tap "owner/repo"           # tap (before using formulae from it)
```

Run `dot brew` to install. Use `dot diff` to see what's missing or extra vs the current system.

## Adding fonts

Drop `.ttf` or `.otf` files into `assets/fonts/`. Run `dot assets` to install them to `~/Library/Fonts`.

## Changing the wallpaper

Replace `assets/wallpapers/wallpaper.png` and run `dot assets`.
