{ ... }:
{
  services.samba = {
    enable = true;

    # Kodi uses SMB2/3 directly on TCP 445. Keep the legacy NetBIOS daemons
    # disabled and restrict the firewall opening to LAN and Tailscale traffic.
    openFirewall = false;
    nmbd.enable = false;
    winbindd.enable = false;

    settings = {
      global = {
        "server role" = "standalone server";
        "server min protocol" = "SMB2";
        "map to guest" = "Never";
        "load printers" = "no";
        "disable spoolss" = "yes";
      };

      Videos = {
        path = "/home/zac/Videos";
        comment = "Kodi media library";
        browseable = "yes";
        "read only" = "yes";
        "guest ok" = "no";
        "valid users" = "zac";
      };
    };
  };

  networking.firewall.interfaces = {
    # The TV reaches the desktop through its wired LAN interface.
    enp6s0.allowedTCPPorts = [ 445 ];
    # Allows Kodi on the laptop to use the same library while connected through
    # the private Tailscale network.
    tailscale0.allowedTCPPorts = [ 445 ];
  };
}
