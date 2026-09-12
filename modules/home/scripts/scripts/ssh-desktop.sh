#!/usr/bin/env bash
set -euo pipefail

# SSH into the desktop over Tailscale SSH (see enable-ssh-tunnel.sh). Hardcoded
# tailnet name since it doesn't change once the node is registered.
exec ssh zac@desktop.tailfbd7af.ts.net "$@"
