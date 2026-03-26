{ username, ... }:
{
  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
    };

    displayManager = {
      sddm = {
        enable = true;
        # Keep the greeter on X11. Hyprland still runs as a Wayland session,
        # but this avoids restarting a Weston-based greeter on NVIDIA.
        wayland.enable = false;
        autoLogin = {
          relogin = true;
        };
      };
      autoLogin = {
        enable = true;
        user = "${username}";
      };
    };
    libinput = {
      enable = true;
    };
  };
  # To prevent getting stuck at shutdown
  systemd.settings.Manager.DefaultTimeoutStopSec = "10s";
}
