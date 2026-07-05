#!/usr/bin/env bash

set -euo pipefail

policy_file="${TALYSMAN_POLICY_FILE:-$HOME/nixos-config/state/talysman-policy.json}"
state_file="${TALYSMAN_STATE_FILE:-/var/lib/talysman/state.json}"
service="${TALYSMAN_SERVICE:-talysman.service}"

if ! command -v jq >/dev/null 2>&1; then
    echo "blocklist-refresh: jq is required but was not found on PATH" >&2
    exit 127
fi

if [ ! -f "$policy_file" ]; then
    echo "blocklist-refresh: policy file not found: $policy_file" >&2
    exit 1
fi

jq -e '
  type == "object"
  and (.mode == "blacklist" or .mode == "whitelist" or .mode == "block-all")
  and (.domains | type == "array")
  and all(.domains[]; type == "string")
  and (.apps | type == "array")
' "$policy_file" >/dev/null

echo "Restarting $service to import $policy_file..."
sudo systemctl restart "$service"

if sudo cat "$state_file" | jq -e --slurpfile policy "$policy_file" '.policy == $policy[0]' >/dev/null; then
    echo "Talysman policy refreshed from $policy_file."
else
    echo "blocklist-refresh: service restarted, but $state_file does not match $policy_file" >&2
    exit 1
fi
