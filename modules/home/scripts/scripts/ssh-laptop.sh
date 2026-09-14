#!/usr/bin/env bash
set -euo pipefail

# SSH into the laptop over Tailscale SSH. Mirror of ssh-desktop; the `laptop`
# alias (host, tailnet IP, user) is defined in modules/home/ssh.nix.
exec ssh laptop "$@"
