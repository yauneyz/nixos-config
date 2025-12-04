{ pkgs, lib, ... }:
{
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        lock_cmd = "";
        before_sleep_cmd = "";
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
      };

      listener = [
        {
          # Screen off after 5 minutes of inactivity
          timeout = 300;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };
}
