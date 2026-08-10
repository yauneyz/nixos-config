{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    window_rule = [
      {
        match.class = "^(Viewnior)$";
        float = true;
      }
      {
        match.class = "^(imv)$";
        float = true;
      }
      {
        match.class = "^(mpv)$";
        float = true;
      }
      {
        match.class = "^(Aseprite)$";
        tile = true;
      }
      {
        match.class = "^(rofi)$";
        pin = true;
      }
      {
        match.class = "^(waypaper)$";
        pin = true;
      }

      {
        match.title = "^(Transmission)$";
        float = true;
      }
      {
        match.title = "^(Volume Control)$";
        float = true;
        size = [
          700
          450
        ];
        move = [
          40
          "55%"
        ];
      }
      {
        match.title = "^(Firefox( Developer Edition)? — Sharing Indicator)$";
        float = true;
        move = [
          0
          0
        ];
      }

      {
        match.title = "^(Picture-in-Picture)$";
        float = true;
        opacity = "1.0 override 1.0 override";
        pin = true;
      }
      {
        match.title = "^(.*imv.*)$";
        opacity = "1.0 override 1.0 override";
      }
      {
        match.title = "^(.*mpv.*)$";
        opacity = "1.0 override 1.0 override";
      }
      {
        match.class = "(Aseprite)";
        opacity = "1.0 override 1.0 override";
      }
      {
        match.class = "(Unity)";
        opacity = "1.0 override 1.0 override";
      }
      {
        match.class = "(zen)";
        opacity = "1.0 override 1.0 override";
      }
      {
        match.class = "(evince)";
        opacity = "1.0 override 1.0 override";
      }

      # Window assignments carried over from i3.
      {
        match.class = "(?i)thinky";
        workspace = "1";
      }
      {
        match.class = "^(talysman-desktop)$";
        workspace = "1";
        size = [
          1160
          720
        ];
        center = true;
      }
      {
        match.class = "^(spotify)$";
        workspace = "14";
      }
      {
        match.class = "^(owl-dev)$";
        workspace = "9";
      }

      {
        match.class = "^(file_progress)$";
        float = true;
      }
      {
        match.class = "^(confirm)$";
        float = true;
      }
      {
        match.class = "^(dialog)$";
        float = true;
      }
      {
        match.class = "^(download)$";
        float = true;
      }
      {
        match.class = "^(notification)$";
        float = true;
      }
      {
        match.class = "^(error)$";
        float = true;
      }
      {
        match.class = "^(confirmreset)$";
        float = true;
      }
      {
        match.title = "^(Open File)$";
        float = true;
      }
      {
        match.title = "^(File Upload)$";
        float = true;
      }
      {
        match.title = "^(branchdialog)$";
        float = true;
      }
      {
        match.title = "^(Confirm to replace files)$";
        float = true;
      }
      {
        match.title = "^(File Operation Progress)$";
        float = true;
      }

      {
        match.class = "^(xwaylandvideobridge)$";
        opacity = "0.0 override";
        no_anim = true;
        no_initial_focus = true;
        size = [
          1
          1
        ];
        no_blur = true;
      }

      # No gaps when only one tiled window is present.
      {
        match = {
          float = false;
          workspace = "w[t1]";
        };
        border_size = 0;
        rounding = 0;
      }
      {
        match = {
          float = false;
          workspace = "w[tg1]";
        };
        border_size = 0;
        rounding = 0;
      }
      {
        match = {
          float = false;
          workspace = "f[1]";
        };
        border_size = 0;
        rounding = 0;
      }

      # Remove context-menu transparency in Chromium-based apps.
      {
        match = {
          class = "^()$";
          title = "^()$";
        };
        opaque = true;
        no_shadow = true;
        no_blur = true;
      }
    ];

    layer_rule = [
      {
        match.namespace = "vicinae";
        dim_around = true;
      }
      {
        match.namespace = "rofi";
        dim_around = true;
      }
      {
        match.namespace = "swaync-control-center";
        dim_around = true;
      }
    ];

    workspace_rule = [
      {
        workspace = "w[t1]";
        gaps_out = 0;
        gaps_in = 0;
      }
      {
        workspace = "w[tg1]";
        gaps_out = 0;
        gaps_in = 0;
      }
      {
        workspace = "f[1]";
        gaps_out = 0;
        gaps_in = 0;
      }
    ];
  };
}
