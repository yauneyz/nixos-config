{
  description = "FrostPhoenix's nixos configuration";

  inputs = {
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

    maple-mono = {
      url = "github:subframe7536/maple-font/variable";
      flake = false;
    };

    superfile.url = "github:yorukot/superfile";
    vicinae.url = "github:vicinaehq/vicinae";
    zen-browser.url = "github:0xc000022070/zen-browser-flake/beta";

    # Thinky source (private repo)
    owl = {
      url = "git+ssh://git@github.com/yauneyz/owl.git?ref=master";
      flake = false;
    };

  };

  outputs =
    { nixpkgs, self, stylix, ... }@inputs:
    let
      username = "zac";
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      lib = nixpkgs.lib;
    in
    {
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
