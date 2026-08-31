#!/usr/bin/env bash
set -euo pipefail

dreamrunner_dir="${DREAMRUNNER_DIR:-$HOME/development/dreamrunner}"
nixos_config_dir="${NIXOS_CONFIG_DIR:-$HOME/nixos-config}"
host="${1:-$(hostname -s)}"

if [[ ! -x "$dreamrunner_dir/scripts/release-local.sh" ]]; then
  echo "Dreamrunner release script not found: $dreamrunner_dir/scripts/release-local.sh" >&2
  exit 1
fi

if [[ ! -f "$nixos_config_dir/scripts/rebuild.sh" ]]; then
  echo "NixOS rebuild script not found: $nixos_config_dir/scripts/rebuild.sh" >&2
  exit 1
fi

NIXOS_CONFIG_DIR="$nixos_config_dir" \
  bash "$dreamrunner_dir/scripts/release-local.sh" "$host"

# Match the Thinky/Talysman local-release flow: stage, then use the standard rebuild.
bash "$nixos_config_dir/scripts/rebuild.sh" "$host"

echo "Dreamrunner local release and hot-reload launcher updated."
