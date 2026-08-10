{ pkgs, config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];

  environment.systemPackages = with pkgs; [
    acpi
    brightnessctl
    cpupower-gui
    powertop
  ];

  services = {
    power-profiles-daemon.enable = true;
    logind = {
      # Explicitly suspend only when the lid closes
      settings = {
        Login = {
          HandleLidSwitch = "suspend";
          HandleLidSwitchExternalPower = "suspend";
        };
      };
    };

    # Talysman distraction blocker
    talysman.enable = true;

    upower = {
      enable = true;
      percentageLow = 20;
      percentageCritical = 5;
      percentageAction = 3;
      criticalPowerAction = "PowerOff";
    };

    # TLP disabled - conflicts with power-profiles-daemon
    # Using power-profiles-daemon instead for simpler power management
    # tlp.settings = { ... };
  };

  powerManagement.cpuFreqGovernor = "performance";

  boot = {
    loader = {
      systemd-boot.enable = false;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev";
        useOSProber = false;
        efiInstallAsRemovable = false;
        extraEntries = ''
          menuentry "Windows Boot Manager" --class windows {
            insmod part_gpt
            insmod fat
            insmod chain
            search --no-floppy --file --set=esp /EFI/Microsoft/Boot/bootmgfw.efi
            chainloader ($esp)/EFI/Microsoft/Boot/bootmgfw.efi
          }
        '';
        # The laptop ESP is 256M; three Zen initrds plus kernels can fill /boot.
        configurationLimit = 2;
      };

    };
    kernelModules = [ "acpi_call" ];
    extraModulePackages =
      with config.boot.kernelPackages;
      [
        acpi_call
        cpupower
      ]
      ++ [ pkgs.cpupower-gui ];
  };

  zac.grubTheme = "cyber-xero";
}
