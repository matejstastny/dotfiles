![Banner](./assets/repo/banner.png)

## Nix Darwin first time setup

First install Nix:

```bash
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)
```

Apply the flake:

```bash
sudo nix run nix-darwin --extra-experimental-features "nix-command flakes" -- \
  switch --flake "$HOME/dotfiles#macbook"
```

## When changing the flake file

```bash
sudo darwin-rebuild switch --flake ~/dotfiles#macbook
```
