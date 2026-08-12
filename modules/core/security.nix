{ pkgs, ... }:
{
  security = {
    rtkit.enable = true;
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };

    polkit = {
      enable = true;
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              subject.user == "zac") {
            return polkit.Result.YES;
          }
        });
      '';
    };

    pam.services = {
      swaylock = { };
      hyprlock = { };
    };

    wrappers.vicinae-input-server = {
      source = "${pkgs.vicinae}/libexec/vicinae/vicinae-input-server";
      capabilities = "cap_dac_override+ep";
      owner = "root";
      group = "root";
    };
  };
}
