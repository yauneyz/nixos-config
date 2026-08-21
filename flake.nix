{
  description = "Zac Yauney's nixos configuration";

  inputs = {
    # Use the Hydra-tested channel explicitly. Leaving this input indirect lets
    # the machine registry select uncached pre-release snapshots on updates.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gaming.url = "github:fufexan/nix-gaming";
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    maple-mono = {
      url = "github:subframe7536/maple-font/variable";
      flake = false;
    };

    snorlax = {
      # Host-agnostic leaf symlink created by modules/home/symlinks.nix. A leaf
      # symlink is accepted by nix's git fetcher; a symlinked *parent* (like the
      # desktop's ~/development) is not — hence the dedicated ~/.snorlax-src.
      url = "git+file:///home/zac/.snorlax-src";
      flake = false;
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    superfile.url = "github:yorukot/superfile";
    vicinae.url = "github:vicinaehq/vicinae";
    zen-browser.url = "github:0xc000022070/zen-browser-flake/beta";

  };

  outputs =
    { nixpkgs, self, stylix, ... }@rawInputs:
    let
      # Nix 2.33's flake git fetcher can preserve the ~/.snorlax-src symlink as
      # the input's store object. Re-fetch the locked revision with fetchGit so
      # evaluators see a normal source directory rather than a store symlink.
      inputs = rawInputs // {
        snorlax = builtins.fetchGit {
          url = "/home/zac/.snorlax-src";
          inherit (rawInputs.snorlax) rev;
        };
      };
      username = "zac";
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          inputs.fenix.overlays.default
          inputs.claude-code.overlays.default
          (final: prev:
            (import ./pkgs {
              inherit inputs;
              pkgs = final;
              inherit prev;
              inherit (prev) system;
            })
          )
        ];
      };
      lib = nixpkgs.lib;
    in
    {
      # Export custom packages for direct building
      packages.${system} = {
        inherit (pkgs)
          chatgpt-linux
          claude-desktop
          readfence
          screenplain
          snorlax
          snorlax-daemon
          talysman
          talysman-daemon
          thinky
          ;
      };

      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/desktop
            stylix.nixosModules.stylix
          ];
          specialArgs = {
            host = "desktop";
            inherit self inputs username;
          };
        };
        laptop = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/laptop
            stylix.nixosModules.stylix
          ];
          specialArgs = {
            host = "laptop";
            inherit self inputs username;
          };
        };
        vm = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/vm
            stylix.nixosModules.stylix
          ];
          specialArgs = {
            host = "vm";
            inherit self inputs username;
          };
        };
      };
    };
}
