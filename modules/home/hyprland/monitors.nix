{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    settings = {
      monitor = [ "eDP-1,3072x1920@60,0x0,2" ];
    };

    extraConfig = ''
      # hyprlang noerror true
        source = ~/.config/hypr/monitors.conf
        source = ~/.config/hypr/workspaces.conf
      # hyprlang noerror false
    '';
  };

  home.packages = with pkgs; [ nwg-displays ];
}
