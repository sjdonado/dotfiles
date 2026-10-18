{
  description = "Workspace provisioning for macOS (nix-darwin) and Linux (home-manager): the one place this workspace is declared, changed and upgraded";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Installs and owns Homebrew itself, at the brew version this lock pins.
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Every Homebrew tap is an input, so a tap moves only when flake.lock does (`mutableTaps = false` in nix/darwin/homebrew.nix).
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-sjdonado = {
      url = "github:sjdonado/homebrew-tap";
      flake = false;
    };
    homebrew-driceroland = {
      url = "github:driceroland/homebrew-tap";
      flake = false;
    };

    # The Pi harness scheme. Pinned here instead of cloned from main on every run; nix/home/common.nix installs it.
    pss = {
      url = "github:sjdonado/pi-skin-sjdonado";
      flake = false;
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      nix-darwin,
      nix-homebrew,
      ...
    }:
    let
      lib = nixpkgs.lib;
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

      # Linux: user and home come from the environment, so one configuration fits any box (a Coder workspace runs as `coder`, a VM as someone else). Reading them needs `--impure`.
      linux =
        system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./nix/home/common.nix
            ./nix/home/linux.nix
            {
              home.username = builtins.getEnv "USER";
              home.homeDirectory = builtins.getEnv "HOME";
            }
          ];
        };

      # macOS: keyed by hostname, with the users named explicitly. One Mac has one nix-darwin system, so every account on it is listed here; the first is the primary user, who owns Homebrew and the system settings. Each user gets the same home configuration, linked into their own ~/.config/dotfiles clone.
      darwin =
        users: extraModules:
        nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit inputs users;
            user = builtins.head users;
          };
          modules = [
            {
              nixpkgs.hostPlatform = "aarch64-darwin";
              nixpkgs.config.allowUnfree = true;
            }
            ./nix/darwin/system.nix
            nix-homebrew.darwinModules.nix-homebrew
            ./nix/darwin/homebrew.nix
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              # The first switch keeps one copy of whatever sat at a managed path (the links lib/links.sh made, a real ~/.hushlogin) as <path>.pre-nix instead of refusing to activate.
              home-manager.backupFileExtension = "pre-nix";
              # A tool that replaces its link with a real file (an atomic save) is backed up again on the next switch instead of stopping it because the backup exists.
              home-manager.overwriteBackup = true;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users = lib.genAttrs users (_: {
                imports = [
                  ./nix/home/common.nix
                  ./nix/home/darwin.nix
                ];
              });
            }
          ]
          ++ extraModules;
        };

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      apps = import ./nix/apps.nix { inherit inputs; };
    in
    {
      darwinConfigurations = {
        "Juans-MacBook-Pro" = darwin [ "sjdonado" "juan" ] [ ];
      };

      homeConfigurations = {
        "linux-aarch64" = linux "aarch64-linux";
        "linux-x86_64" = linux "x86_64-linux";
      };

      apps = lib.genAttrs systems (system: apps (pkgsFor system));
    };
}
