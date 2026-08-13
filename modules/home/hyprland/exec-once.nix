{ config, lib, ... }:
let
  backendCommands =
    if config.zac.desktop.shell.backend == "quickshell" then
      [ "systemctl --user start zac-quickshell.service" ]
    else
      [
        "waybar"
        "swaync"
        "swayosd-server"
      ];
  commands = [
    "dbus-update-activation-environment --all --systemd PATH WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE"
    "systemctl --user import-environment PATH WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE"
    "nm-applet"
    "poweralertd"
    # caffeine-ng ships its own XDG autostart .desktop file, which systemd's
    # xdg-desktop-autostart.target already picks up (app-caffeine@autostart.service) --
    # launching it here too produced two tray icons.
    # "both" also grabs the primary selection, which wl-clip-persist's own docs
    # warn breaks the selection system in some apps; a wedged read early in
    # startup leaves GTK apps (pgtk Emacs) unable to paste until restarted.
    "wl-clip-persist --clipboard regular"
  ]
  ++ backendCommands
  ++ [
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
