{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  scanDir = "${config.zac.paths.home}/Main/scans";
  printerName = "Brother_MFC-L3710CW";
in
{
  # Driverless printing (IPP Everywhere / AirPrint) and scanning (eSCL).
  services.printing = {
    enable = true;
    # The queue below is explicit; browsed would add a duplicate of it.
    browsed.enable = false;
  };

  # Brother MFC-L3710CW on the home LAN. Not hardware.printers.ensurePrinters:
  # that runs in cups' ExecStartPost and kills cups whenever the printer is
  # unreachable (laptop away from home, printer off at boot). Instead, add the
  # queue once when the printer is reachable; cups keeps it after that.
  systemd.services.brother-printer-queue = {
    description = "Add Brother MFC-L3710CW print queue";
    after = [
      "cups.socket"
      "cups.service"
      "avahi-daemon.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ config.services.printing.package ];
    serviceConfig.Type = "oneshot";
    script = ''
      if lpstat -p ${printerName} >/dev/null 2>&1; then
        exit 0
      fi
      if lpadmin -p ${printerName} -E \
        -v ipp://BRWBCF4D47D6DD0.local:631/ipp/print \
        -m everywhere \
        -D "Brother MFC-L3710CW" \
        -L Home \
        -o PageSize=Letter; then
        lpadmin -d ${printerName}
      else
        echo "Printer unreachable; will retry."
      fi
    '';
  };

  systemd.timers.brother-printer-queue = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "15min";
    };
  };

  # mDNS discovery plus .local hostname resolution for printers.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.sane-airscan ];
    # airscan replaces escl; keep it from showing every scanner twice.
    disabledDefaultBackends = [ "escl" ];
  };

  environment.systemPackages = with pkgs; [
    simple-scan
    system-config-printer
  ];

  users.users.${username}.extraGroups = [
    "lp"
    "scanner"
  ];

  home-manager.users.${username} =
    { lib, ... }:
    {
      dconf.settings."org/gnome/SimpleScan".save-directory = "file://${scanDir}";

      home.activation.createScanDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p ${lib.escapeShellArg scanDir}
      '';
    };
}
