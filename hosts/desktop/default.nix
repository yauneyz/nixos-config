{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];

  boot.loader = {
    systemd-boot.enable = false;

    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };

    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
      efiInstallAsRemovable = false;
      # theme = "${pkgs.kdePackages.breeze-grub}/grub/themes/breeze";
      theme = "${pkgs.fetchFromGitHub {
        owner = "sergoncano";
        repo = "hollow-knight-grub-theme";
        rev = "master";
        sha256 = "sha256-0hn3MFC+OtfwtA//pwjnWz7Oz0Cos3YzbgUlxKszhyA=";
      }}/hollow-grub";
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  # Enable focusd distraction blocker
  # Token and blocklist are symlinked from dotfiles via tmpfiles
  services.focusd.enable = true;

  # Create symlinks from /etc to dotfiles for focusd
  systemd.tmpfiles.rules = [
    "L+ /etc/focusd/token.sha256 - - - - /data/zac/zac/dotfiles/focusd/token.sha256"
    "L+ /etc/blocklist.yml - - - - /data/zac/zac/dotfiles/focusd/blocklist.yml"
  ];

  hardware = {
    graphics = {
      enable = true;
    };

    nvidia = {
      open = true;
    };
  };

  powerManagement.cpuFreqGovernor = "performance";
}
