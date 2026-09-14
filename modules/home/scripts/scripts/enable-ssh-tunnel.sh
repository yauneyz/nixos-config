#!/usr/bin/env bash
set -euo pipefail

# Interactive Tailscale login for a machine that isn't on the tailnet yet
# (fresh install, or after a re-auth). The SSH server itself is now declarative
# - modules/core/tailscale.nix runs `tailscale set --ssh` on every activation -
# so this script only covers the part that has to be done by a human.
#
# Idempotent: safe to re-run.

echo "Bringing this machine onto the tailnet (SSH server is enabled by NixOS)..."
sudo tailscale up --ssh

echo
echo "Done. This machine's tailnet name/IP:"
tailscale status --self --json | grep -E '"DNSName"|"TailscaleIPs"' || true
echo
echo "From the other machine, connect with the aliases in modules/home/ssh.nix:"
echo "  ssh desktop   (or: ssh-desktop)"
echo "  ssh laptop    (or: ssh-laptop)"
echo
echo "If a connection asks you to 'visit https://login.tailscale.com/a/...',"
echo "that is the tailnet ACL policy using ssh action \"check\": approve once in"
echo "the browser and it is cached for the policy's checkPeriod (12h by"
echo "default). Switch that rule to action \"accept\" at"
echo "https://login.tailscale.com/admin/acls to stop being asked."
