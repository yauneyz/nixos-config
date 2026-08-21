#!/usr/bin/env bash
set -euo pipefail

thinky_dir="${THINKY_DIR:-$HOME/development/clojure/owl}"
nixos_config_dir="${NIXOS_CONFIG_DIR:-$HOME/nixos-config}"
host="${1:-$(hostname)}"

if [[ ! -d "$thinky_dir" ]]; then
  echo "Thinky project directory not found: $thinky_dir" >&2
  exit 1
fi

if [[ ! -f "$nixos_config_dir/scripts/rebuild.sh" ]]; then
  echo "NixOS rebuild script not found: $nixos_config_dir/scripts/rebuild.sh" >&2
  exit 1
fi

cd "$thinky_dir"
pnpm run release:local

# This is the same rebuild command used by the `rebuild` shell alias.
bash "$nixos_config_dir/scripts/rebuild.sh" "$host"

echo "Thinky local release updated."
