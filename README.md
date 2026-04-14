<div align="center">
<img src="./assets/repo/holymoly.png" width="25%" align="right"/>
<br>

# ✦ dotfiles

_macOS · managed with [`dot`](bin/dot)_

</div>

<br>

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/matejstastny/dotfiles/main/bootstrap.sh)"
```

```sh
git clone https://github.com/matejstastny/dotfiles.git ~/dotfiles
~/dotfiles/bin/dot all
```

<br>

<details>
<summary>&nbsp;&nbsp;<code>dot</code>&nbsp;&nbsp;·&nbsp;&nbsp;commands</summary>

<br>

```
  link      symlink configs to system locations
  brew      install & update homebrew packages
  assets    install fonts and set wallpaper

  update    brew + link
  all       run everything

  check     show symlink status
  diff      brewfile vs installed
```

`link` accepts `--force` and `--dry-run`

<br>

</details>

<details>
<summary>&nbsp;&nbsp;<code>configs</code>&nbsp;&nbsp;·&nbsp;&nbsp;what's included</summary>

<br>

|              |                |
| ------------ | -------------- |
| `ghostty`    | terminal       |
| `vscode`     | IDE            |
| `nvim`       | text editor    |
| `tmux`       | multiplexer    |
| `zsh`        | shell          |
| `sketchybar` | status bar     |
| `aerospace`  | window manager |
| `oh-my-posh` | prompt         |
| `btop`       | system monitor |
| `fastfetch`  | fetch          |

<br>
</details>
<br>
