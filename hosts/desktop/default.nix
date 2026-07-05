{ config, pkgs, ... }:
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

  # Enable Talysman distraction blocker
  services.talysman.enable = true;

  hardware = {
    graphics = {
      enable = true;
    };

    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.production;
      open = false;
      modesetting.enable = true;
      powerManagement.enable = true;
      nvidiaSettings = true;
      nvidiaPersistenced = true;
    };
  };

  # Avoid switch-time restarts when the NVIDIA userspace package changes but the
  # old kernel module is still loaded. The daemon will start normally at boot.
  systemd.services.nvidia-persistenced.restartIfChanged = false;

  powerManagement.cpuFreqGovernor = "performance";
}
