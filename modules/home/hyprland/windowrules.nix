{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "float on, match:class ^(Viewnior)$"
      "float on, match:class ^(imv)$"
      "float on, match:class ^(mpv)$"
      "tile on, match:class ^(Aseprite)$"
      "pin on, match:class ^(rofi)$"
      "pin on, match:class ^(waypaper)$"
      # "idleinhibit focus,mpv"
      # "float,udiskie"
      "float on, match:title ^(Transmission)$"
      "float on, match:title ^(Volume Control)$"
      "float on, match:title ^(Firefox — Sharing Indicator)$"
      "move 0 0, match:title ^(Firefox — Sharing Indicator)$"
      "size 700 450, match:title ^(Volume Control)$"
      "move 40 55%, match:title ^(Volume Control)$"

      "float on, match:title ^(Picture-in-Picture)$"
      "opacity 1.0 override 1.0 override, match:title ^(Picture-in-Picture)$"
      "pin on, match:title ^(Picture-in-Picture)$"
      "opacity 1.0 override 1.0 override, match:title ^(.*imv.*)$"
      "opacity 1.0 override 1.0 override, match:title ^(.*mpv.*)$"
      "opacity 1.0 override 1.0 override, match:class (Aseprite)"
      "opacity 1.0 override 1.0 override, match:class (Unity)"
      "opacity 1.0 override 1.0 override, match:class (zen)"
      "opacity 1.0 override 1.0 override, match:class (evince)"
      # === Window assignments from i3 ===
      "workspace 1, match:class (?i)thinky"
      "workspace 14, match:class ^(spotify)$"

      # === Firefox by title ===
      "workspace 13, match:title .*Google Keep.*"
      "workspace 13, match:title .*YouTube.*"

      # === Emacs by title ===
      "workspace 3, match:class ^(Emacs)$, match:title .*PdfWindow\\.cljs.*"
      "workspace 9, match:class ^(Emacs)$, match:title .*owl/todo\\.org.*"
      "workspace 15, match:class ^(Emacs)$, match:title .*misc/todo\\.org.*"

      # === Development terminals ===
      "workspace 9, match:class ^(owl-dev)$"

      # === Other workspace assignments ===
      "float on, match:class ^(file_progress)$"
      "float on, match:class ^(confirm)$"
      "float on, match:class ^(dialog)$"
      "float on, match:class ^(download)$"
      "float on, match:class ^(notification)$"
      "float on, match:class ^(error)$"
      "float on, match:class ^(confirmreset)$"
      "float on, match:title ^(Open File)$"
      "float on, match:title ^(File Upload)$"
      "float on, match:title ^(branchdialog)$"
      "float on, match:title ^(Confirm to replace files)$"
      "float on, match:title ^(File Operation Progress)$"

      "opacity 0.0 override, match:class ^(xwaylandvideobridge)$"
      "no_anim on, match:class ^(xwaylandvideobridge)$"
      "no_initial_focus on, match:class ^(xwaylandvideobridge)$"
      "size 1 1, match:class ^(xwaylandvideobridge)$"
      "no_blur on, match:class ^(xwaylandvideobridge)$"

      # No gaps when only
      "border_size 0, match:float 0, match:workspace w[t1]"
      "rounding 0, match:float 0, match:workspace w[t1]"
      "border_size 0, match:float 0, match:workspace w[tg1]"
      "rounding 0, match:float 0, match:workspace w[tg1]"
      "border_size 0, match:float 0, match:workspace f[1]"
      "rounding 0, match:float 0, match:workspace f[1]"

      # "maxsize 1111 700, floating: 1"
      # "center, floating: 1"

      # Remove context menu transparency in chromium based apps
      "opaque on, match:class ^()$, match:title ^()$"
      "no_shadow on, match:class ^()$, match:title ^()$"
      "no_blur on, match:class ^()$, match:title ^()$"
    ];

    layerrule = [
      "dim_around on, match:namespace vicinae"
      "dim_around on, match:namespace rofi"
      "dim_around on, match:namespace swaync-control-center"
    ];

    # No gaps when only
    workspace = [
      "w[t1], gapsout:0, gapsin:0"
      "w[tg1], gapsout:0, gapsin:0"
      "f[1], gapsout:0, gapsin:0"
    ];
  };
}
