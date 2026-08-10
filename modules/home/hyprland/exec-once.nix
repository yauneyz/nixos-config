{ lib, ... }:
let
  commands = [
    "dbus-update-activation-environment --all --systemd PATH WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE"
    "systemctl --user import-environment PATH WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE"
    "nm-applet"
    "poweralertd"
    "wl-clip-persist --clipboard both"
    "wl-paste --watch cliphist store"
    "waybar"
    "swaync"
    "vicinae server"
    "udiskie --automount --notify --smart-tray"
    "hyprctl setcursor Bibata-Modern-Ice 24"
    "ghostty --gtk-single-instance=true --quit-after-last-window-closed=false --initial-window=false"
    # Launch apps on designated workspaces via Hyprland's dispatcher API.
    "hypr-startup"
  ];
  startFunction = lib.generators.mkLuaInline ''
    function()
    ${lib.concatMapStrings (command: "  hl.exec_cmd(${builtins.toJSON command})\n") commands}end
  '';
in
{
  wayland.windowManager.hyprland.settings.on = [
    {
      _args = [
        "hyprland.start"
        startFunction
      ];
    }
  ];
}
