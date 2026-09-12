#!/usr/bin/env bash

set -euo pipefail

state_root="${XDG_STATE_HOME:-$HOME/.local/state}/monitor-brightness-toggle"
state_file="$state_root/brightness.tsv"
lock_file="$state_root/lock"

notify_user() {
  if command -v notify-send > /dev/null 2>&1; then
    notify-send --app-name="Monitor brightness" "$@" || true
  fi
}

mkdir -p "$state_root"
exec 9>"$lock_file"
if ! flock -n 9; then
  notify_user "Brightness toggle already running"
  exit 0
fi

mapfile -t detected_displays < <(
  ddcutil detect --brief 2> /dev/null |
    awk '
      /^Display [0-9]+$/ { display = $2 }
      /DRM connector:/ && display != "" { print display "\t" $3 }
    '
)

if (( ${#detected_displays[@]} == 0 )); then
  notify_user "No DDC/CI monitors found" "Check that DDC/CI is enabled in the monitor menus."
  exit 1
fi

declare -a display_numbers=()
declare -a connectors=()
declare -a current_values=()
any_monitor_lit=false

for detected in "${detected_displays[@]}"; do
  IFS=$'\t' read -r display connector <<< "$detected"
  brightness_output=$(ddcutil getvcp 10 --display "$display" --brief 2> /dev/null) || {
    notify_user "Could not read $connector brightness"
    exit 1
  }
  read -r _ _ _ current maximum <<< "$brightness_output"

  if [[ ! "$current" =~ ^[0-9]+$ || ! "$maximum" =~ ^[0-9]+$ ]]; then
    notify_user "Unexpected brightness response from $connector" "$brightness_output"
    exit 1
  fi

  display_numbers+=("$display")
  connectors+=("$connector")
  current_values+=("$current")
  if (( current > 0 )); then
    any_monitor_lit=true
  fi
done

if [[ "$any_monitor_lit" == true ]]; then
  temporary_state=$(mktemp "$state_file.XXXXXX")
  trap 'rm -f "$temporary_state"' EXIT

  for index in "${!display_numbers[@]}"; do
    printf '%s\t%s\n' "${connectors[$index]}" "${current_values[$index]}" >> "$temporary_state"
  done
  mv "$temporary_state" "$state_file"
  trap - EXIT

  for display in "${display_numbers[@]}"; do
    ddcutil setvcp 10 0 --display "$display" > /dev/null
  done
  notify_user "Monitors darkened" "Saved brightness for ${#display_numbers[@]} monitor(s)."
  exit 0
fi

if [[ ! -s "$state_file" ]]; then
  notify_user "No saved brightness to restore" "Raise a monitor above zero once, then toggle again."
  exit 1
fi

restored=0
for index in "${!display_numbers[@]}"; do
  connector="${connectors[$index]}"
  saved=$(awk -F '\t' -v connector="$connector" '$1 == connector { print $2; exit }' "$state_file")

  if [[ ! "$saved" =~ ^[0-9]+$ || "$saved" -gt 100 ]]; then
    continue
  fi

  ddcutil setvcp 10 "$saved" --display "${display_numbers[$index]}" > /dev/null
  ((restored += 1))
done

if (( restored == 0 )); then
  notify_user "Saved monitors are not connected" "Brightness was not changed."
  exit 1
fi

notify_user "Monitor brightness restored" "Restored $restored monitor(s)."
