{ ... }:
{
  # Installs KDE Connect and opens its standard TCP/UDP discovery and transfer
  # range (1714-1764). kdeconnectd is started in the graphical user session by
  # the package's XDG autostart entry; the Hyprland config also starts its tray
  # indicator so pairing and connection state remain easy to reach.
  programs.kdeconnect.enable = true;
}
