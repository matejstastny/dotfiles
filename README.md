![repository banner](./assets/repository/banner.png)

# ~/.dotfiles

My dofiles for apps I use for development on MacOS. [_GNU Stow_](https://www.gnu.org/software/stow/manual/stow.html) was used to create symlinks of the conf files. Most of the files are configured to match the [Catppuccin](https://catppuccin.com/) _Mocha_ theme. My [wallpaper](./assets/wallpaper.png) is also included.

## Installation

This script automates the installation of essential tools, configurations, and settings for macOS. It installs Homebrew, essential CLI utilities, terminal applications, menubar apps, and macOS system settings.

### Steps to Install:

Run the following commands in your terminal:

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/kireiiiiiiii/dotfiles/refs/heads/main/install.sh)"
```

### What the Installation Script Does:

1. **Installs Xcode CLI Tools**

   - Ensures the required development tools are available

2. **Installs [Homebrew](https://brew.sh/) & Disables Analytics**

   - Homebrew is used for package management
   - Turns off analytics for privacy

3. **Installs Essential CLI Utilities via Homebrew**

   - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
   - [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
   - [stow](https://www.gnu.org/software/stow/)
   - [bat](https://github.com/sharkdp/bat)
   - [btop](https://github.com/aristocratos/btop)
   - [scc](https://github.com/boyter/scc)
   - [fd](https://github.com/sharkdp/fd)
   - [zoxide](https://github.com/ajeetdsouza/zoxide)
   - [eza](https://github.com/eza-community/eza)
   - [prettier](https://github.com/prettier/prettier)
   - [make](https://www.gnu.org/software/make/)
   - [gh](https://github.com/cli/cli)
   - [npm](https://github.com/npm/cli)

4. **Installs GUI Applications via Homebrew Casks**

   - [Raycast](https://www.raycast.com/)
   - [Arc](https://arc.net/)
   - [Visual Studio Code](https://code.visualstudio.com/)
   - [WezTerm](https://wezfurlong.org/wezterm/)
   - [Alacritty](https://alacritty.org/)
   - [Ghostty](https://ghostty.app/)

5. **Tweaks macOS System Settings**

   - Configures the dock to auto-hide
   - Reduces key repeat delays

6. **Clones and Stows Dotfiles**

   - Uses `stow` to symlink configuration files to the home directory

7. **Installs Custom Fonts**

   - All fonts from `~/.dotfiles/assets/fonts/` are installed

8. **Sets Custom Wallpaper**
   - Uses [wallpaper-cli](https://github.com/sindresorhus/wallpaper-cli) to set the desktop wallpaper

After running the script, your environment should be fully configured with the necessary tools and settings.

> [!NOTE]
> If you are using a fresh macOS installation, you may need to manually allow permissions for certain applications in **System Preferences > Security & Privacy**.

---

## Manual installation

Install [Homebrew](https://brew.sh/), [Git](https://git-scm.com/) and [Stow](https://www.gnu.org/software/stow/manual/stow.html) using these commands:

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install git
brew install stow
```

Next, you need to clone this repository:

```shell
git clone https://github.com/kireiiiiiiii/dotfiles.git $HOME/.dotfiles
```

In order for the fonts to work, you need to move font files from this repo into your system fonts folder. This is how you do it on MacOS:

```shell
find ~/.dotfiles/assets/fonts -type f -exec cp {} /Library/Fonts \;
```

To create all the config simlings Run the following command, to clone this dotfiles repo into your home directory

```shell
cd ~/.dotfiles
stow --restow -t ~ .
```
