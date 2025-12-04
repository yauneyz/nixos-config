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
    "[workspace 2 silent] firefox --new-window"
    "[workspace 13 silent] firefox --new-window https://keep.google.com"
    "[workspace 13 silent] firefox --new-window https://youtube.com"

    # === Editors (Emacs) ===
    "[workspace 3 silent] emacs ~/development/clojure/owl/electron/src/app/components/PdfWindow.cljs"
    "[workspace 9 silent] emacs ~/development/clojure/owl/todo.org"
    "[workspace 11 silent] emacs ~/development/org/working-memory.org"
    "[workspace 12 silent] emacs ~/development/go/tutorial/"
    "[workspace 15 silent] emacs ~/development/org/misc/todo.org"

    # === Development Terminals ===

		# TODO - figure out how to make go-services work properly
    #"[workspace 9 silent] ghostty --class go-services -e bash -c 'cd /home/zac/development/go/wikidex; bash start-dev.sh'"
    "[workspace 9 silent] ghostty -e bash -c 'cd /home/zac/development/clojure/owl/electron && npm run develop'"
    "[workspace 10 silent] ghostty -e bash -c 'cd /home/zac/development/clojure/owl/electron && npm run start'"

    # === Media ===
    "[workspace 14 silent] spotify"
  ];
}
