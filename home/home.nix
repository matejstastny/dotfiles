{ config, pkgs, ... }:

{
  home.username = "matejstastny";
  home.homeDirectory = "/Users/matejstastny";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  # ZSH
  home.file.".zshrc".source = ./zsh/.zshrc;
  home.file.".zprofile".source = ./zsh/.zprofile;

  # GIT
  home.file.".gitconfig".source = ./git/.gitconfig;

  # VSCode
  home.file.".config/Code/User/settings.json".source = ./vscode/settings.json;
  home.file.".config/Code/User/keybindings.json".source = ./vscode/keybindings.json;

  # Vesktop
  home.file.".config/vesktop/themes/midnight.theme.css".source = ./vesktop/midnight.theme.css;

  # .config
  home.file.".config/nvim".source = ./nvim;
  home.file.".config/bat".source = ./bat;
  home.file.".config/fastfetch".source = ./fastfetch;
  home.file.".config/sketchybar".source = ./sketchybar;
  home.file.".config/tmux".source = ./tmux;
  home.file.".config/ghostty".source = ./ghostty;
  home.file.".config/borders".source = ./borders;
  home.file.".config/aerospace".source = ./aerospace;
}
