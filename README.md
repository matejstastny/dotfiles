![repository banner](./public/banner.png)

# dofiles

My dofiles for apps I use for developmentm usind the _gnu stow_ on my MacOS laptop.

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
