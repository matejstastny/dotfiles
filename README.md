![repository banner](./public/banner.png)

# dotfiles

My dofiles for apps I use for development on my MacOS laptop. [_GNU Stow_](https://www.gnu.org/software/stow/manual/stow.html) was used to create symlinks of the conf files. All of the files are configured to match the [Catppuccin](https://catppuccin.com/) _Mocha_ theme. My [wallpaper](./wallpaper.png) is also included.

## Requirements

### [Homebrew](https://brew.sh/)

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### [Git](https://git-scm.com/)

```shell
brew install git
```

### [Stow](https://www.gnu.org/software/stow/manual/stow.html)

```shell
brew install stow
```

## Setup

Run the following command, to clone this dotfiles repo into your home directory. WARNING: The directory must be in `$HOME`

```shell
git clone https://github.com/kireiiiiiiii/dotfiles.git $HOME/dotfiles
```

Next step is to create the symlinks using stow. Run the following command to create symlinks from the directory you just cloned.

```shell
cd ~/dotfiles
stow .
```

---

## [Alacritty](https://github.com/alacritty/alacritty)

My primary terminal emulator. To install run:

```shell
brew install alacritty
```

![Alacritty terminal screenshot](./public/alacritty.png)

## [Kitty](https://sw.kovidgoyal.net/kitty/)

My secondary terminal emulator. To install run:

```shell
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
```

![Kitty terminal screenshot](./public/kitty.png)

## [Neovim](https://neovim.io/)

My primary code editor. It's a heavily modified version of [NVChad](https://nvchad.com/) To install run:

```shell
brew install neovim
```

![Neovim code editor screenshot](./public/neovim.png)

## [Tmux](https://github.com/tmux/tmux)

My terminal window manager. I use terminal only with it. To install run:

```shell
brew install tmux
```

![Tmux running in Alacritty screenshot](./public/tmux.png)
