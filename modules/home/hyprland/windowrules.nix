{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "float,class:^(Viewnior)$"
      "float,class:^(imv)$"
      "float,class:^(mpv)$"
      "tile,class:^(Aseprite)$"
      "pin,class:^(rofi)$"
      "pin,class:^(waypaper)$"
      # "idleinhibit focus,mpv"
      # "float,udiskie"
      "float,title:^(Transmission)$"
      "float,title:^(Volume Control)$"
      "float,title:^(Firefox — Sharing Indicator)$"
      "move 0 0,title:^(Firefox — Sharing Indicator)$"
      "size 700 450,title:^(Volume Control)$"
      "move 40 55%,title:^(Volume Control)$"

      "float, title:^(Picture-in-Picture)$"
      "opacity 1.0 override 1.0 override, title:^(Picture-in-Picture)$"
      "pin, title:^(Picture-in-Picture)$"
      "opacity 1.0 override 1.0 override, title:^(.*imv.*)$"
      "opacity 1.0 override 1.0 override, title:^(.*mpv.*)$"
      "opacity 1.0 override 1.0 override, class:(Aseprite)"
      "opacity 1.0 override 1.0 override, class:(Unity)"
      "opacity 1.0 override 1.0 override, class:(zen)"
      "opacity 1.0 override 1.0 override, class:(evince)"
      # === Window assignments from i3 ===
      "workspace 9, title:^(Shadow-CLJS)$"
      "workspace 9, title:^(Go Services)$"
      "workspace 9, class:^(go-services)$"
      "workspace 10, title:^(Electron)$"
      "workspace 12, class:^(Spotify)$"
      "workspace 11, class:^(firefox)$,title:^(.*keep-profile.*)$"
      "workspace 11, class:^(firefox)$,title:^(.*music-youtube.*)$"

      # === Other workspace assignments ===
      "float,class:^(file_progress)$"
      "float,class:^(confirm)$"
      "float,class:^(dialog)$"
      "float,class:^(download)$"
      "float,class:^(notification)$"
      "float,class:^(error)$"
      "float,class:^(confirmreset)$"
      "float,title:^(Open File)$"
      "float,title:^(File Upload)$"
      "float,title:^(branchdialog)$"
      "float,title:^(Confirm to replace files)$"
      "float,title:^(File Operation Progress)$"

      "opacity 0.0 override,class:^(xwaylandvideobridge)$"
      "noanim,class:^(xwaylandvideobridge)$"
      "noinitialfocus,class:^(xwaylandvideobridge)$"
      "maxsize 1 1,class:^(xwaylandvideobridge)$"
      "noblur,class:^(xwaylandvideobridge)$"

      # No gaps when only
      "bordersize 0, floating:0, onworkspace:w[t1]"
      "rounding 0, floating:0, onworkspace:w[t1]"
      "bordersize 0, floating:0, onworkspace:w[tg1]"
      "rounding 0, floating:0, onworkspace:w[tg1]"
      "bordersize 0, floating:0, onworkspace:f[1]"
      "rounding 0, floating:0, onworkspace:f[1]"

      # "maxsize 1111 700, floating: 1"
      # "center, floating: 1"

      # Remove context menu transparency in chromium based apps
      "opaque,class:^()$,title:^()$"
      "noshadow,class:^()$,title:^()$"
      "noblur,class:^()$,title:^()$"
    ];

    layerrule = [
      "dimaround, vicinae"
      "dimaround, rofi"
      "dimaround, swaync-control-center"
    ];

    # No gaps when only
    workspace = [
      "w[t1], gapsout:0, gapsin:0"
      "w[tg1], gapsout:0, gapsin:0"
      "f[1], gapsout:0, gapsin:0"
    ];
  };
}
