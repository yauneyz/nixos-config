{ pkgs, host, ... }:
{
  services = {
    gvfs.enable = true;

    gnome = {
      tinysparql.enable = true;
      gnome-keyring.enable = true;
    };

    dbus.enable = true;
    fstrim.enable = true;

    # needed for GNOME services outside of GNOME Desktop
    dbus.packages = with pkgs; [
      gcr
      gnome-settings-daemon
    ];


    udisks2.enable = true;

    postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
    };
  };

  systemd.services.nixos-rebuild-daily = {
    description = "Daily NixOS Rebuild";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake /home/zac/nixos-config#${host}";
    };
    path = with pkgs; [ git ];
  };

  systemd.timers.nixos-rebuild-daily = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "17:00";
      Persistent = true;
      Unit = "nixos-rebuild-daily.service";
    };
  };
}
