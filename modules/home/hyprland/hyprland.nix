{ pkgs, ... }:
{
  home.packages = with pkgs; [
    awww # Wallpaper daemon for per-monitor wallpaper support
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

    # The NixOS programs.hyprland module in modules/core/wayland.nix owns the
    # Hyprland and portal packages. If Home Manager installs them too, its
    # xdg.portal module exports NIX_XDG_DESKTOP_PORTAL_DIR pointing at the user
    # profile, which only contains the Hyprland portal and hides the system GTK
    # portal. Electron then finds org.freedesktop.portal.Desktop but reports
    # "No such interface org.freedesktop.portal.FileChooser" because XDPH does
    # not implement file picking. Keep portal discovery system-owned so the GTK
    # FileChooser and Hyprland screen-sharing backends are both available.
    package = null;
    portalPackage = null;

    # Hyprland 0.55 deprecated Hyprlang; Home Manager renders the structured
    # settings below to ~/.config/hypr/hyprland.lua.
    configType = "lua";
    xwayland = {
      enable = true;
      # hidpi = true;
    };
    systemd.enable = true;
  };
}
