{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    settings = {
      # Set to 120Hz for smoother experience
      monitor = [ "eDP-1,3072x1920@120,0x0,2" ];
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
