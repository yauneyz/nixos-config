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
