{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    settings = {
      cursor = {
        no_hardware_cursors = true;
      };

      monitor = [
        # DP-1: Left monitor (portrait, rotated 90° CW)
        # Resolution: 3840x2160, becomes 2160x3840 after rotation
        # Scale: 1.5
        "DP-1,3840x2160@60,0x0,1.5,transform,3"

        # DP-2: Right monitor (landscape, primary)
        # Position: offset by rotated DP-1's scaled width (2160/1.5 = 1440)
        # Scale: 1.2
        "DP-2,3840x2160@60,1440x0,1.2"

        # Fallback for any other monitors
        ",preferred,auto,auto"
      ];

      workspace = [
        # Left monitor (DP-1) - workspaces 8, 9, 10
        "8, monitor:DP-1, default:true"
        "9, monitor:DP-1"
        "10, monitor:DP-1"

        # Right monitor (DP-2) - workspaces 1-7, 11-15
        "1, monitor:DP-2, default:true"
        "2, monitor:DP-2"
        "3, monitor:DP-2"
        "4, monitor:DP-2"
        "5, monitor:DP-2"
        "6, monitor:DP-2"
        "7, monitor:DP-2"
        "11, monitor:DP-2"
        "12, monitor:DP-2"
        "13, monitor:DP-2"
        "14, monitor:DP-2"
        "15, monitor:DP-2"
      ];
    };
  };

  home.packages = with pkgs; [ nwg-displays ];
}
