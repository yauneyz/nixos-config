{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # swww  # Replaced by Stylix wallpaper management
    grimblast
    hyprpicker
    grim
    slurp
    wl-clip-persist
    cliphist
    wf-recorder
    glib
    wayland
    direnv
  ];
  systemd.user.targets.hyprland-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland = {
      enable = true;
      # hidpi = true;
    };
    systemd.enable = true;
  };
}
