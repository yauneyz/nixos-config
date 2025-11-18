{ ... }:
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

    # ⬇️ this is the important bit
    device = "nodev";

    useOSProber = true;
    efiInstallAsRemovable = false;
  };
};



  powerManagement.cpuFreqGovernor = "performance";
}
