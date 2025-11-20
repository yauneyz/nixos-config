{ pkgs, ... }:
{
  boot = {
    loader = {
     # systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
     # systemd-boot.configurationLimit = 10; # Only for systemd-boot, not GRUB
    };

    kernelPackages = pkgs.linuxPackages_zen;
    supportedFilesystems = [ "ntfs" ];
  };
}
