#!/usr/bin/env bash

set -euo pipefail

MONITOR="DP-1"
MONITOR_LAYOUT_FILE="${MONITOR_LAYOUT_FILE:-$HOME/nixos-config/modules/home/hyprland/monitors-desktop.nix}"

apply_monitor_layout() {
  local config_file="$1"

  if [ ! -f "$config_file" ]; then
    echo "[toggle-monitor] Monitor layout file not found: $config_file" >&2
    exit 1
  fi

  echo "[toggle-monitor] Re-applying monitor layout from $config_file"
  local configs
  configs=$(
    awk '
      /monitor[[:space:]]*=/ && /\[/ { in_monitor = 1; next }
      in_monitor && /\];/ { exit }
      in_monitor {
        sub(/#.*/, "", $0)
        if (match($0, /"([^"]+)"/, m)) {
          print m[1]
        }
      }
    ' "$config_file"
  )

  if [ -z "$configs" ]; then
    echo "[toggle-monitor] No monitor entries found in $config_file" >&2
    exit 1
  fi

  while IFS= read -r monitor_config; do
    [ -z "$monitor_config" ] && continue
    echo "[toggle-monitor] Applying monitor config: $monitor_config"
    hyprctl keyword monitor "$monitor_config"
  done <<< "$configs"
}

echo "[toggle-monitor] Querying Hyprland monitors..."
monitors_json=$(hyprctl -j monitors all 2> /dev/null)

if [ -z "$monitors_json" ]; then
  echo "[toggle-monitor] Unable to query Hyprland monitors" >&2
  exit 1
fi

echo "[toggle-monitor] Current monitors:"
echo "$monitors_json" | jq -r '.[] | "  \(.name): disabled=\(.disabled), resolution=\(.width)x\(.height), scale=\(.scale)"'

monitor_disabled=$(echo "$monitors_json" | jq -r --arg monitor "$MONITOR" '.[] | select(.name == $monitor) | .disabled')

if [ "$monitor_disabled" = "true" ] || [ -z "$monitor_disabled" ]; then
  echo "[toggle-monitor] Monitor $MONITOR currently disabled or missing -> re-applying layout"
  apply_monitor_layout "$MONITOR_LAYOUT_FILE"
else
  echo "[toggle-monitor] Monitor $MONITOR currently enabled -> disabling"
  hyprctl keyword monitor "$MONITOR,disable"
fi
