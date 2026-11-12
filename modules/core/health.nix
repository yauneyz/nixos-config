{ pkgs, ... }:
{
  # Compressed swap in RAM. It takes priority over the on-disk swap partition,
  # which stays as overflow. memoryPercent is a ceiling, not a reservation.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  # Tuning recommended for zram-backed swap: swapping to RAM is cheap, so
  # prefer it over dropping page cache, and don't read ahead.
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.page-cluster" = 0;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
  };

  services = {
    # Kill the biggest memory hog before the desktop freezes. Prefer model
    # servers and compilers, and never pick the compositor/shell/audio stack.
    earlyoom = {
      enable = true;
      freeMemThreshold = 4;
      freeSwapThreshold = 10;
      enableNotifications = true;
      extraArgs = [
        "--prefer"
        "(^|/)(llama-server|ollama|ollama_llama_server|python3?|cc1plus|rustc|node)$"
        "--avoid"
        "(^|/)(Hyprland|Xwayland|quickshell|waybar|ghostty|pipewire|wireplumber|systemd|sshd|tailscaled)$"
      ];
    };

    # Firmware updates from LVFS (BIOS, NVMe/SSD, peripherals):
    #   fwupdmgr refresh && fwupdmgr get-updates && fwupdmgr update
    fwupd.enable = true;

    # Disk health monitoring. Runs a short self-test daily and a long one
    # weekly (NixOS default schedule), and warns via desktop notification +
    # wall on failures or degrading SMART attributes.
    smartd = {
      enable = true;
      autodetect = true;
      notifications = {
        wall.enable = true;
        systembus-notify.enable = true;
      };
    };
  };

  environment.systemPackages = [ pkgs.smartmontools ];
}
