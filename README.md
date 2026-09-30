![the elara palette](assets/palette.png)

# elara

personal fedora asahi setup and the desktop shell it runs.

the pi fleet lives in its own repo, [`rpi`](https://github.com/matejstastny/rpi).
other machines live on their own branches with unrelated history: `macos`,
`ubuntu`, and `arch`.

## start here

- [`configs/quickshell`](configs/quickshell) is the qml desktop shell, about
  7,000 lines of the visible desktop.
- [`configs`](configs) is everything linked into `~/.config`.
- [`scripts`](scripts) contains the desktop actions, while [`bin`](bin) is
  longer-lived command-line tooling.
- [`install`](install) is the machine setup, including the local quickshell
  build.

## using it

`bin/link --dry-run` shows the symlinks this repository would make.
`bin/link` makes only missing links, and leaves existing files alone.

```sh
just check
just fmt
```

`just check` parses the shell and python. it needs `just` and python.
`just fmt` needs `shfmt`.

## stack

fedora asahi remix · hyprland · quickshell · zsh · kitty

the palette comes from `assets/palette.png`. elara is a moon of jupiter.
