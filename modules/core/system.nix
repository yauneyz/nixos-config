{ pkgs, host, ... }:
let
  llamaCppPackage =
    if host == "desktop" then
      pkgs.llama-cpp.override { cudaSupport = true; }
    else
      pkgs.llama-cpp;
in
{
  # imports = [ inputs.nix-gaming.nixosModules.default ];
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
#        "https://nix-community.cachix.org"
#        "https://nix-gaming.cachix.org"
#        "https://hyprland.cachix.org"
#        "https://ghostty.cachix.org"
#        "https://vicinae.cachix.org"
      ];
      trusted-public-keys = [
#        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
#        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
#        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
#        "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
#        "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      ];
    };
  };

  systemd.services.nixos-flake-update = {
    description = "Update nixpkgs flake input for nixos-config";
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = "/home/zac/nixos-config";
      ExecStart = "/run/current-system/sw/bin/nix flake lock --update-input nixpkgs --update-input claude-code --update-input codex-cli-nix";
      User = "zac";
    };
  };

  systemd.timers.nixos-flake-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "10m";
      OnUnitActiveSec = "12h";
      Persistent = true;
    };
  };

  environment.systemPackages = with pkgs; [
    wget
    git
    libxcrypt-legacy
    p7zip
    steam-run
    gsettings-desktop-schemas
    lsof
    psmisc
    maim                              # CLI screenshot tool
    slop                              # region selector used with maim
    usbutils                          # provides lsusb
    wineWow64Packages.stable
    winetricks
    llamaCppPackage
    #python3Packages.torch
  ];

  # Upstream Python docs build is currently failing (Sphinx/docutils).
  # Keep package docs out of system-path so rebuilds remain unblocked.
  documentation.doc.enable = false;

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.05";
}
