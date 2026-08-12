{ ... }:
{
  zac.desktop.shell.backend = "quickshell";

  imports = [
    ./default.nix
    ./hyprland/monitors-desktop.nix
    ./video-ai
  ];
}
