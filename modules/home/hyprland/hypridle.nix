{ pkgs, lib, ... }:
{
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
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
        {
          # Lock screen after 10 minutes
          timeout = 600;
          on-timeout = "loginctl lock-session";
        }
        {
          # Suspend after 15 minutes (only if lid is already closed or on battery)
          timeout = 900;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
