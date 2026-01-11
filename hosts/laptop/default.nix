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
      lidSwitch = "suspend";
      lidSwitchExternalPower = "suspend";
    };

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
	useOSProber = true;
	efiInstallAsRemovable = false;

		theme = "${pkgs.fetchFromGitHub {
			owner = "sergoncano";
			repo = "hollow-knight-grub-theme";
			rev = "master";
			sha256 = "sha256-0hn3MFC+OtfwtA//pwjnWz7Oz0Cos3YzbgUlxKszhyA=";
		}}/hollow-grub";
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
}
