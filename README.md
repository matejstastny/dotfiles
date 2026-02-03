<h1 align="center">dotfiles</h1>

<p align="center">
    <img src="./assets/screenshots/1.png" alt="screenshot 1">
    <img width="49%" src="./assets/screenshots/2.png" alt="screenshot 2">
    <img width="49%" src="./assets/screenshots/3.png" alt="screenshot 3">
</p>

---

Personal dotfiles with custom scripts to manage it, like for example a symlinker script.

Includes:

- Symlinked configs
- Homebrew setup
- Fonts & wallpapers

## Quick start

```bash
git clone https://github.com/matejstastny/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x dot
./bin/dot all
```

> [!NOTE] This is kinda broken, but I am too unbothered to fix the scripts. If it's like a fresh system, it will have wierd issuses. If you install homebrew manually and then run the link script and then the asset script, it should work as intended.

## Usage

```bash
./dot [link|brew|assets|all]...
```

- `link` – Symlinks configs
- `brew` – Install & update Homebrew packages
- `assets` – Install fonts and set wallpaper
- `all` – Run everything

You can combine steps:

```bash
./dot brew assets
```

## Link script

Most configs are linked as whole directories into `~/.config` Some configs are linked as files and/or into different locations. The script will ask if it finds a file to override it. If ran with `--force` it just does it. It's kinda cool I am proud of this script. Could i use `stow`? Yeah but this is more fun.

- `zsh`, `git` → as files into `$HOME`
- `vscode` → VS Code user config directory, as files into `Application Support`
- etc.

### Flags:

- overwrite prompts
- `--force` to force override conflict files
- `--dry-run` to show what will happen

## Homebrew script

It installs brew, updates it, updates all packages and install all stuff from the `Brewfile`. Its lowk broken, I might fix it someday.

## Asset script

Installs the `Dank Mono Nerd Fond` that I use for my mono font, and sets wallpaper to [this](./assets/wallpapers/mac-wallpaper.jpg).
