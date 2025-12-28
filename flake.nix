# --------------------------------------------------------------------------------------------
# flake.nix - my macbook nix-darwin system flake
# --------------------------------------------------------------------------------------------
# Author: Matej Stastny
# Date: 2025-12-27 (YYYY-MM-DD)
# License: MIT
# Link: https://github.com/matejstastny/dotfiles
# --------------------------------------------------------------------------------------------

{
  description = "🌸 my-daarlin's nix-darwin system flake 🌸";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
    }:
    let
      configuration =
        { pkgs, config, ... }:
        {
          environment.systemPackages = with pkgs; [
            ## 🌱 Core utilities
            mkalias
            coreutils
            curl
            wget
            bash
            zsh-syntax-highlighting

            ## 🐱 CLI tools
            bat
            btop
            eza
            fastfetch
            fzf
            zoxide
            tmux
            neovim

            ## 🌳 Git & version control
            gh
            git
            git-lfs
            lazygit

            ## 🛠 Tools
            docker
            nixfmt

            ## 💻 UI and WM
            sketchybar
            aerospace
          ];

          system.primaryUser = "matejstastny";

          # 🧁 Services
          services.sketchybar.enable = true;

          # ----------------------------------------------------
          # 🍎 macOS Applications integration
          # Creates /Applications/Nix Apps with Finder aliases
          # ----------------------------------------------------

          system.activationScripts.applications.text =
            let
              env = pkgs.buildEnv {
                name = "system-applications";
                paths = config.environment.systemPackages;
                pathsToLink = [ "/Applications" ];
              };
            in
            pkgs.lib.mkForce ''
              echo "🌸 setting up /Applications/Nix Apps..." >&2
              rm -rf /Applications/Nix\ Apps
              mkdir -p /Applications/Nix\ Apps

              find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
              while read -r src; do
                app_name=$(basename "$src")
                echo "✨ linking $app_name" >&2
                ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
              done
            '';

          # 🌸 Home manager
          users.users.matejstastny.home = "/Users/matejstastny";

          # ⚙️ Nix & system settings
          nix.settings.experimental-features = "nix-command flakes";
          system.configurationRevision = self.rev or self.dirtyRev or null;
          system.stateVersion = 6;
          nixpkgs.hostPlatform = "aarch64-darwin";
        };
    in
    {
      darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.matejstastny = import ./home/home.nix;
          }
        ];
      };
    };
}
