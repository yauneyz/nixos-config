{ ... }:
{
  wayland.windowManager.hyprland.settings.exec-once = [
    # "hash dbus-update-activation-environment 2>/dev/null"
    "dbus-update-activation-environment --all --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

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
    "firefox --new-window https://keep.google.com"
    "firefox --new-window https://youtube.com"

    # === Editors (Emacs) ===
    "emacs ~/development/clojure/owl/electron/src/app/components/PdfWindow.cljs"
    "emacs ~/development/clojure/owl/todo.org"
    "emacs ~/development/org/misc/todo.org"

    # === Development Terminals ===
    "ghostty --class=owl-dev -e bash -c 'cd /home/zac/development/clojure/owl/electron && npm run develop'"

    # === Media ===
    "spotify"
  ];
}
