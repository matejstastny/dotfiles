![Banner](./assets/repository/banner.png)

# Daarlin's Dotfiles

Welcome to Daarlin's Dotfiles repository - a collection of configuration files and scripts tailored for development on macOS. This setup uses [_GNU Stow_](https://www.gnu.org/software/stow/manual/stow.html) to manage symlinks, ensuring a clean and maintainable configuration environment.

This repository provides a comprehensive macOS development environment setup, including essential tools, utilities, GUI applications, system tweaks, and personalized configurations. The installation process is designed to be straightforward, either via an automated script or manual commands, depending on your preference.

## Repository Structure

```
.dotfiles/
├── assets/
│   ├── fonts/          # Dank Mono nerd font
│   ├── repository/     # Repo assets (banner, screenshots)
│   └── wallpapers/     # Wallpapers for mac and for a Windows VM
├── .config/            # Configuration dotfiles
├── Library             # VS Code settings and keybindings
├── .zshrc
├── install.sh          # Automated installation script
└── README.md
```

### 1. Install Homebrew

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Install Git and GNU Stow

```shell
brew install git
brew install stow
```

### Cloning the Dotfiles Repository

```shell
git clone https://github.com/my-daarlin/dotfiles.git $HOME/.dotfiles
```

### Creating Symlinks with GNU Stow

GNU Stow is a symlink manager that helps keep your dotfiles organized. Each folder inside `.dotfiles` corresponds to a set of configurations for an application or tool. To restow (create symlinks) all configurations run the following command:

```shell
stow --restow -t ~ .
```

### Font Installation

The repository includes custom font, the [Dank Mono](https://philpl.gumroad.com/l/dank-mono) in it's normal and [Nerd Font](https://www.nerdfonts.com/) versions located under [`assets/fonts/`](./assets/fonts/). Installing these fonts ensures consistent typography across your terminal and applications. Use the following command to install fonts:

```shell
find ~/.dotfiles/assets/fonts -type f -exec cp {} /Library/Fonts \;
```

### Setting the Wallpaper

Custom wallpapers from my Macbook and Widnows VM are included in the repository at [`assets/wallpapers`](./assets/wallpapers/). To set it, install [`wallpaper`](https://formulae.brew.sh/formula/wallpaper) and run:

```shell
wallpaper set ~/.dotfiles/assets/mac-wallpaper.png
```

## Screenshots

_TODO_

---

Thank you for using Daarlin's Dotfiles! For questions or contributions, please open an issue or submit a pull request on the [GitHub repository](https://github.com/kireiiiiiiii/dotfiles).

---

> [!CAUTION]
> This script does not work how it's supposed to yet. Do not use it unless you know what you're doing!

## Automated Installation

To streamline the setup, an installation script is provided which automates the following steps:

1. **Install Xcode Command Line Tools**
   Ensures that essential development tools are available on macOS.

2. **Install Homebrew & Disable Analytics**
   Homebrew is the package manager used for installing CLI utilities and applications. Analytics are disabled for privacy.

3. **Install Essential CLI Utilities via Homebrew**
   Installs widely used command-line tools including:

   - `zsh-autosuggestions`
   - `zsh-syntax-highlighting`
   - `stow`
   - `bat`
   - `btop`
   - `scc`
   - `fd`
   - `zoxide`
   - `eza`
   - `prettier`
   - `make`
   - `gh` (GitHub CLI)
   - `npm`

4. **Install GUI Applications via Homebrew Casks**
   Installs popular GUI apps such as:

   - Raycast
   - Arc Browser
   - Visual Studio Code
   - WezTerm Terminal
   - Alacritty Terminal
   - Ghostty

5. **Configure macOS System Settings**
   Applies system customizations like:

   - Dock auto-hide
   - Reduced key repeat delays

6. **Clone and Stow Dotfiles**
   Uses GNU Stow to symlink configuration files to your home directory.

7. **Install Custom Fonts**
   Installs all fonts located in `~/.dotfiles/assets/fonts/` into the system fonts directory.

8. **Set Custom Wallpaper**
   Uses [wallpaper-cli](https://github.com/sindresorhus/wallpaper-cli) to set the desktop wallpaper to the included image.

### How to Run the Automated Installer

Open your terminal and run:

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/kireiiiiiiii/dotfiles/refs/heads/main/install.sh)"
```
