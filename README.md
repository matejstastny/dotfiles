<div align="center">


# dotfiles
`macOS` configuration managed with a custom `dot` script.

</div>


<br>

<img src="./assets/repo/banner.jpg" alt="banner" align="right" width="18%" />

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/matejstastny/dotfiles/main/bootstrap.sh)"
```

```sh
# manual install
git clone https://github.com/matejstastny/dotfiles.git ~/dotfiles
~/dotfiles/bin/dot all
```

<br>

### `dot`

```
dot <command>

  link      symlink configs to system locations
  brew      install & update homebrew packages
  assets    install fonts and set wallpaper
  update    brew + link
  all       run everything

  check     show symlink status for all configs
  diff      show brewfile vs installed packages
```

flags for `link`: `--force`, `--dry-run`
