#!/usr/bin/env bash
set -euo pipefail

snorlax_dir="${SNORLAX_DIR:-$HOME/development/snorlax}"
nixos_config_dir="${NIXOS_CONFIG_DIR:-$HOME/nixos-config}"
host="${1:-$(hostname)}"

if [[ ! -d "$snorlax_dir" ]]; then
  echo "Talysman source directory not found: $snorlax_dir" >&2
  exit 1
fi

if [[ ! -f "$nixos_config_dir/scripts/rebuild.sh" ]]; then
  echo "NixOS rebuild script not found: $nixos_config_dir/scripts/rebuild.sh" >&2
  exit 1
fi

cd "$snorlax_dir"
pnpm run release:local

# This is the same rebuild command used by the `rebuild` shell alias.
bash "$nixos_config_dir/scripts/rebuild.sh" "$host"

# systemd's Restart=always brings the freshly rebuilt daemon back up.
sudo pkill talysman || true

echo "Talysman local release and daemon updated."
