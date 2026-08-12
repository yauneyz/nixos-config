{
  config,
  lib,
  pkgs,
  ...
}:
let
  enabled = config.zac.desktop.shell.backend == "quickshell";
in
{
  systemd.user.services.zac-quickshell = lib.mkIf enabled {
    Unit = {
      Description = "Zac Quickshell desktop shell";
      Documentation = "file://${./README.md}";
      After = [
        "graphical-session-pre.target"
        "hyprland-session.target"
      ];
      PartOf = [ "hyprland-session.target" ];
    };

    Install.WantedBy = [ "hyprland-session.target" ];

    Service = {
      ExecStart = "${pkgs.quickshell}/bin/qs --config zac-shell --no-duplicate";
      Restart = "on-failure";
      RestartSec = 2;
      TimeoutStopSec = 5;
      Environment = [
        "QS_NO_RELOAD_POPUP=1"
        "QT_QUICK_CONTROLS_STYLE=Basic"
      ];
    };
  };
}
