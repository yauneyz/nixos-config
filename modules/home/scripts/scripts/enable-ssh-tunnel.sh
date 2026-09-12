#!/usr/bin/env bash
set -euo pipefail

# One-shot setup for cross-machine SSH between nixos-config hosts (desktop <->
# laptop). Uses Tailscale SSH instead of managing OpenSSH keys: tailscaled
# runs its own SSH server bound to the tailnet identity, so there is no
# authorized_keys file to maintain and no port to open on the LAN/internet.
#
# Run this once per machine (it's idempotent - safe to re-run).

echo "Requesting Tailscale SSH access for this machine..."
sudo tailscale up --ssh

echo
echo "Done. This machine's tailnet name/IP:"
tailscale status --self --json | grep -E '"DNSName"|"TailscaleIPs"' || true
echo
echo "From the other machine (once it has also run this script), connect with:"
echo "  ssh zac@<this-machine-tailnet-name>"
echo
echo "If the connection is refused, check the tailnet's ACL policy at"
echo "https://login.tailscale.com/admin/acls includes an ssh rule permitting"
echo "this - the default personal-account policy already does."
