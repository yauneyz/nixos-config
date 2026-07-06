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
          # Screen off after 5 minutes of inactivity.
          # Deliberately no on-resume: waking is only via the Super+Shift+S
          # dpms toggle bind, and an on-resume "dpms on" races with that
          # toggle (input fires both, and toggle can flip the screen back off).
          timeout = 300;
          on-timeout = "hyprctl dispatch dpms off";
        }
      ];
    };
  };
}
