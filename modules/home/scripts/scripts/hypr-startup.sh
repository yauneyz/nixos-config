#!/usr/bin/env bash
# Sequential startup: switch workspace, launch app, wait, repeat.

# === Workspace 3: Emacs (PdfWindow) ===
hyprctl dispatch workspace 3
emacs ~/development/clojure/owl/electron/src/app/components/PdfWindow.cljs &
sleep 2

# === Workspace 9: Emacs (owl todo) + owl-dev terminal ===
ghostty --class=owl-dev -e bash -c 'cd /home/zac/development/clojure/owl/electron && npm run develop; exec bash' &
sleep 2
hyprctl dispatch workspace 9
emacs ~/development/clojure/owl/todo.org &
sleep 2

# === Workspace 10: owl start terminal ===
hyprctl dispatch workspace 10
ghostty -e bash -c 'cd /home/zac/development/clojure/owl/electron && npm run start; exec bash' &
sleep 2

# === Workspace 13: Firefox ===
hyprctl dispatch workspace 13
firefox --new-window https://keep.google.com https://keep.google.com https://keep.google.com https://keep.google.com &
sleep 5
firefox --new-window https://youtube.com &
sleep 3

# === Workspace 14: Spotify ===
hyprctl dispatch workspace 14
spotify &
sleep 2

# === Workspace 15: Emacs (misc todo) ===
hyprctl dispatch workspace 15
emacs ~/development/org/misc/todo.org &
sleep 2

# === Return to workspace 13 ===
hyprctl dispatch workspace 13
