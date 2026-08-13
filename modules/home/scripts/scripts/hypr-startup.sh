#!/usr/bin/env bash
# Sequential startup: switch workspace, launch app, wait, repeat.

# Wait until the compositor's clipboard plumbing answers before launching any
# apps. wl-paste exits with "No selection" once the data-control protocol is
# live, so treat that as ready too; GTK apps started before this point can end
# up with a permanently dead clipboard until restarted.
for _ in $(seq 1 30); do
  out=$(wl-paste --list-types 2>&1) && break
  case "$out" in *"No selection"*) break ;; esac
  sleep 0.2
done

# Wait for the status bar's layer-shell surface to map before switching
# workspaces. The bar reserves an exclusive zone on each monitor, and if that
# reservation lands after windows have already been placed, monitor layout
# can still be settling while we're dispatching workspace switches, causing
# apps to end up on the wrong workspace.
for _ in $(seq 1 30); do
  namespaces=$(hyprctl layers -j 2>/dev/null | jq -r '.[].levels // {} | .[][] | .namespace' 2>/dev/null)
  case "$namespaces" in *zac-shell-bar*|*waybar*) break ;; esac
  sleep 0.2
done

# === Workspace 3: Emacs (Snorlax web prompt) ===
hyprctl dispatch workspace 3
#emacs ~/development/clojure/owl/electron/src/app/components/PdfWindow.cljs &
emacs ~/development/snorlax/apps/web/prompts/current.org &
sleep 2

# === Workspace 9: Emacs (Snorlax current work) ===
#ghostty --class=owl-dev -e bash -c 'cd /home/zac/development/clojure/owl/electron && npm run develop; exec bash' &
#ghostty --class=owl-dev -e bash -c 'cd /home/zac/development/jirachi && bun run dev; exec bash' &
sleep 2

hyprctl dispatch workspace 9
#emacs ~/development/clojure/owl/todo.org &
emacs ~/development/snorlax/current.org &
sleep 2

# === Workspace 10: owl start terminal ===
#hyprctl dispatch workspace 10
#ghostty -e bash -c 'cd /home/zac/development/clojure/owl/electron && npm run start; exec bash' &
#sleep 2

# === Workspace 13: Firefox ===
hyprctl dispatch workspace 13
firefox-devedition --new-window https://keep.google.com https://keep.google.com https://keep.google.com https://keep.google.com &
sleep 5
firefox-devedition --new-window https://youtube.com &
sleep 3

# === Workspace 15: Emacs (misc todo) ===
hyprctl dispatch workspace 15
emacs ~/development/org/misc/todo.org &
sleep 2

# === Return to workspace 13 ===
hyprctl dispatch workspace 13
