{ config, ... }:
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
    };
  };

  # Theme sets use collection.variant names; standalone themes use one name.
  zac.grubTheme = "sekiro.shadow";

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
