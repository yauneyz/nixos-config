#!/usr/bin/env bash
set -euo pipefail

# SSH into the desktop over Tailscale SSH. The `desktop` alias (host, tailnet
# IP, user) is defined in modules/home/ssh.nix, so this doesn't hardcode an
# address of its own.
exec ssh desktop "$@"
