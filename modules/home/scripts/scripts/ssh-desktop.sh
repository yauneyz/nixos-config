#!/usr/bin/env bash
set -euo pipefail

# SSH into the desktop over Tailscale SSH. The `desktop` alias (host, tailnet
# IP, user) is defined in modules/home/ssh.nix, so this doesn't hardcode an
# address of its own.

# Tint the terminal while the session is open, the same as the zsh `ssh`
# wrapper does -- this runs as its own binary, so it never sees that function.
# Note: no `exec`, or the trap would never fire.
if [ -t 1 ] && [ -r "${XDG_CONFIG_HOME:-$HOME/.config}/ssh-tint.sh" ]; then
    # shellcheck source=/dev/null
    . "${XDG_CONFIG_HOME:-$HOME/.config}/ssh-tint.sh"
    trap ssh_tint_clear EXIT INT
    ssh_tint_set
fi

ssh desktop "$@"
