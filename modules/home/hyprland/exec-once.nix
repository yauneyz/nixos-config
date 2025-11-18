{ ... }:
{
  wayland.windowManager.hyprland.settings.exec-once = [
    # "hash dbus-update-activation-environment 2>/dev/null"
    "dbus-update-activation-environment --all --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

    "hyprlock"

    "nm-applet &"
    "poweralertd &"
    "wl-clip-persist --clipboard both &"
    "wl-paste --watch cliphist store &"
    "waybar &"
    "swaync &"
    "vicinae server &"
    "udiskie --automount --notify --smart-tray &"
    "hyprctl setcursor Bibata-Modern-Ice 24 &"
    "init-wallpaper &"

    "ghostty --gtk-single-instance=true --quit-after-last-window-closed=false --initial-window=false"

    # === Browsers ===
    "[workspace 2 silent] firefox --new-window"
    "[workspace 11 silent] firefox --no-remote --new-window -P keep-profile"
    "[workspace 11 silent] firefox --new-window -P music-youtube https://youtube.com"

    # === Editors (Emacs) ===
    "[workspace 3 silent] emacsclient -c -a \"\" ~/development/clojure/owl/electron/src/app/components/PdfWindow.cljs"
    "[workspace 9 silent] emacsclient -c -a \"\" ~/development/owl/todo.org"
    "[workspace 13 silent] emacsclient -c -a \"\" ~/development/org/misc/todo.org"
    "[workspace 14 silent] emacsclient -c -a \"\" ~/development/org/working-memory.org"
    "[workspace 15 silent] emacsclient -c -a \"\" ~/development/go/tutorial/"

    # === Development Terminals ===
    "[workspace 9 silent] ghostty --class go-services -e bash -c 'cd /home/zac/development/go/wikidex; bash start-dev.sh'"

    # === Media ===
    "[workspace 12 silent] spotify-launcher"
  ];
}
