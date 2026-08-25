#!/usr/bin/env bash
# Startup launcher: fire each app, wait for its window to actually appear,
# then move it to the target workspace with a single one-shot dispatcher
# call. This is deliberately NOT done via a permanent class-based
# window_rule: Emacs and Firefox windows should stay completely free to drag
# to any workspace during the day. A one-shot move at boot is indistinguishable
# from the user pressing the ALT+SHIFT+<workspace key> bind themselves right
# after the window opens -- nothing "remembers" the assignment or fights a
# later manual move. (Spotify/owl-dev/thinky keep their existing permanent
# class rules in windowrules.nix -- those are single-purpose apps that only
# ever belong on one workspace.)
#
# Previous versions of this script instead dispatched `hyprctl dispatch
# workspace N` before each launch and hoped the window would appear before
# the next switch. That's a race: DP-1's default workspace (8) is what a
# window lands on whenever the switch hasn't "taken" yet by the time the app
# maps, which is why most windows used to end up there regardless of intent.

# Wait until the compositor's clipboard plumbing answers before launching any
# apps. wl-paste exits with "No selection" once the data-control protocol is
# live, so treat that as ready too; GTK apps started before this point can end
# up with a permanently dead clipboard until restarted.
for _ in $(seq 1 30); do
  out=$(wl-paste --list-types 2>&1) && break
  case "$out" in *"No selection"*) break ;; esac
  sleep 0.2
done

# Wait for the status bar's layer-shell surface to map before launching
# anything. The bar reserves an exclusive zone on each monitor, and if that
# reservation lands after windows have already been placed, monitor layout
# can still be settling while apps are mapping.
for _ in $(seq 1 30); do
  namespaces=$(hyprctl layers -j 2>/dev/null | jq -r '.[].levels // {} | .[][] | .namespace' 2>/dev/null)
  case "$namespaces" in *zac-shell-bar*|*waybar*) break ;; esac
  sleep 0.2
done

snapshot_addresses_for_class() {
  hyprctl clients -j 2>/dev/null | jq -r --arg c "$1" '.[] | select(.class == $c) | .address'
}

# wait_for_new_window <class> <addresses-before> [timeout-seconds] [title-regex]
# Polls for a window of <class> whose address wasn't in the "before"
# snapshot, and prints its address once found. If <title-regex> is given,
# only a new window whose title matches it counts -- this matters whenever
# more than one window of the same class can appear around the same time
# (e.g. a second Firefox window unexpectedly mapping, a session-restore
# window), since otherwise the first new address wins even if it's the
# wrong window.
wait_for_new_window() {
  local class="$1" before="$2" timeout="${3:-20}" title_re="${4:-}" iterations i new match
  iterations=$((timeout * 5))
  for ((i = 0; i < iterations; i++)); do
    new=$(comm -13 <(sort <<<"$before") <(sort <<<"$(snapshot_addresses_for_class "$class")"))
    if [ -n "$new" ]; then
      if [ -z "$title_re" ]; then
        head -n1 <<<"$new"
        return 0
      fi
      match=$(hyprctl clients -j 2>/dev/null |
        jq -r --arg c "$class" --arg t "$title_re" \
          '.[] | select(.class == $c and (.title | test($t))) | .address' |
        grep -Fxf <(printf '%s\n' "$new") | head -n1)
      [ -n "$match" ] && { echo "$match"; return 0; }
    fi
    sleep 0.2
  done
  return 1
}

# One-shot, non-sticky move: identical in effect to the user pressing
# ALT+SHIFT+<key> on the window themselves. No rule is created, so the
# window can be dragged to any other workspace afterward with no fight-back.
move_window_to_workspace_once() {
  local address="$1" workspace="$2"
  hyprctl dispatch "hl.dsp.window.move({workspace = $workspace, window = 'address:$address', follow = false})" >/dev/null
}

# launch_and_place <class-to-match> <workspace> <command...>
# <class-to-match> only needs to be unique long enough to identify the new
# window among whatever else is opening concurrently at boot -- it's not
# written anywhere persistent.
launch_and_place() {
  local class="$1" workspace="$2"
  shift 2
  local before addr
  before=$(snapshot_addresses_for_class "$class")
  "$@" &
  addr=$(wait_for_new_window "$class" "$before") || return 0
  move_window_to_workspace_once "$addr" "$workspace"
}

# Workspace 3: Emacs (Snorlax web prompt)
launch_and_place emacs-snorlax-prompt 3 \
  emacs --name=emacs-snorlax-prompt \
  --eval '(setq frame-title-format (list "%b - GNU Emacs"))' \
  ~/development/snorlax/current.org &

# Workspace 9: Emacs (Snorlax current work)
launch_and_place emacs-snorlax-current 9 \
  emacs --name=emacs-snorlax-current \
  --eval '(setq frame-title-format (list "%b - GNU Emacs"))' \
  ~/development/snorlax/todo.org &

# Workspace 15: Emacs (misc todo)
launch_and_place emacs-misc-todo 15 \
  emacs --name=emacs-misc-todo \
  --eval '(setq frame-title-format (list "%b - GNU Emacs"))' \
  ~/development/org/misc/todo.org &

# Workspace 14 ("o"): Spotify -- placed via the permanent class rule in
# windowrules.nix, since it's single-purpose and always belongs there.
spotify &

# Workspace 13 ("u"): Firefox -- 2 windows, Keep tabs on the left, YouTube on
# the right. Firefox can't use launch_and_place's simple form because the
# second window depends on the first: Firefox's single-instance remoting
# means a fixed sleep between the two launches is unreliable (this is also
# why URLs used to occasionally split across the wrong number of windows) --
# so this waits for each window by address before firing the next command.
# Runs in its own background block so it doesn't block the Emacs launches.
(
  before=$(snapshot_addresses_for_class firefox-devedition)
  firefox-devedition --new-window https://keep.google.com https://keep.google.com https://keep.google.com &
  keep_addr=$(wait_for_new_window firefox-devedition "$before" 20 "Google Keep")
  [ -n "$keep_addr" ] && move_window_to_workspace_once "$keep_addr" 13

  before=$(snapshot_addresses_for_class firefox-devedition)
  firefox-devedition --new-window https://youtube.com &
  youtube_addr=$(wait_for_new_window firefox-devedition "$before" 20 "YouTube")
  [ -n "$youtube_addr" ] && move_window_to_workspace_once "$youtube_addr" 13
) &

# === Disabled experiments (kept for reference) ===
#emacs ~/development/clojure/owl/electron/src/app/components/PdfWindow.cljs &
#ghostty --class=owl-dev -e bash -c 'cd /home/zac/development/clojure/owl/electron && npm run develop; exec bash' &
#ghostty --class=owl-dev -e bash -c 'cd /home/zac/development/jirachi && bun run dev; exec bash' &
#emacs ~/development/clojure/owl/todo.org &
#hyprctl dispatch workspace 10
#ghostty -e bash -c 'cd /home/zac/development/clojure/owl/electron && npm run start; exec bash' &

# Wait for all placement jobs above to finish (they only block on their own
# window appearing, not on the app itself exiting -- the app processes are
# backgrounded inside each job and keep running as orphans once this script
# exits, same as before).
wait

# Land on workspace 13 ("u") once everything has been placed.
hyprctl dispatch workspace 13
