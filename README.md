![repository banner](./assets/repository/banner.png)

# .dotfiles

My dofiles for apps I use for development on MacOS. [_GNU Stow_](https://www.gnu.org/software/stow/manual/stow.html) was used to create symlinks of the conf files. Most of the files are configured to match the [Catppuccin](https://catppuccin.com/) _Mocha_ theme. My [wallpaper](./assets/wallpaper.png) is also included.

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

### [Dank Mono Nerd Fonts](https://www.nerdfonts.com/)

```shell
cp ~/.dotfiles/assets/fonts/dankmono-nerd-font/*.otf /Library/Fonts
```

## Setup

Run the following command, to clone this dotfiles repo into your home directory. WARNING: The directory must be in `$HOME`

```shell
git clone https://github.com/kireiiiiiiii/dotfiles.git $HOME/.dotfiles
```

Next step is to create the symlinks using stow. Run the following command to create symlinks from the directory you just cloned.

```shell
cd ~/.dotfiles
stow .
```
