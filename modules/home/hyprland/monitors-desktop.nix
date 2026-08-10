{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    settings = {
      config.cursor.no_hardware_cursors = true;

      monitor = [
        # DP-1: Left monitor (portrait, rotated 90° CW)
        # Resolution: 3840x2160, becomes 2160x3840 after rotation
        # Scale: 1.5
        {
          output = "DP-1";
          mode = "3840x2160@60";
          position = "0x0";
          scale = 1.5;
          transform = 3;
        }

        # DP-2: Right monitor (landscape, primary)
        # Position: offset by rotated DP-1's scaled width (2160/1.5 = 1440)
        # Scale: 1.2
        {
          output = "DP-2";
          mode = "3840x2160@60";
          position = "1440x0";
          scale = 1.25;
        }

        # Fallback for any other monitors
        {
          output = "";
          mode = "preferred";
          position = "auto";
          scale = "auto";
        }
      ];

      workspace_rule = [
        # Left monitor (DP-1) - workspaces 8, 9, 10
        {
          workspace = "8";
          monitor = "DP-1";
          default = true;
        }
        {
          workspace = "9";
          monitor = "DP-1";
        }
        {
          workspace = "10";
          monitor = "DP-1";
        }

        # Right monitor (DP-2) - workspaces 1-7, 11-15
        {
          workspace = "1";
          monitor = "DP-2";
          default = true;
        }
        {
          workspace = "2";
          monitor = "DP-2";
        }
        {
          workspace = "3";
          monitor = "DP-2";
        }
        {
          workspace = "4";
          monitor = "DP-2";
        }
        {
          workspace = "5";
          monitor = "DP-2";
        }
        {
          workspace = "6";
          monitor = "DP-2";
        }
        {
          workspace = "7";
          monitor = "DP-2";
        }
        {
          workspace = "11";
          monitor = "DP-2";
        }
        {
          workspace = "12";
          monitor = "DP-2";
        }
        {
          workspace = "13";
          monitor = "DP-2";
        }
        {
          workspace = "14";
          monitor = "DP-2";
        }
        {
          workspace = "15";
          monitor = "DP-2";
        }
      ];
    };
  };

  home.packages = with pkgs; [ nwg-displays ];
}
