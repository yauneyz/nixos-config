#!/usr/bin/env bash
# NixOS helper script to merge base /etc/hosts with focusd additions
# This script is called by focusd when enabling/disabling profiles

set -euo pipefail

FOCUSD_ADDITIONS="/var/lib/focusd/hosts-additions"
NIXOS_BASE_HOSTS="/etc/nixos-base-hosts"
HOSTS_FILE="/etc/hosts"
TEMP_HOSTS=$(mktemp)

# Function to clean up temp file on exit
cleanup() {
    rm -f "$TEMP_HOSTS"
}
trap cleanup EXIT

# Start with NixOS base hosts if it exists
if [ -f "$NIXOS_BASE_HOSTS" ]; then
    cat "$NIXOS_BASE_HOSTS" > "$TEMP_HOSTS"
else
    # Fallback: generate minimal base hosts
    cat > "$TEMP_HOSTS" << EOF
# NixOS base hosts
127.0.0.1 localhost
::1 localhost
EOF
fi

# Add a separator
echo "" >> "$TEMP_HOSTS"
echo "# focusd managed entries below" >> "$TEMP_HOSTS"

# Append focusd additions if they exist
if [ -f "$FOCUSD_ADDITIONS" ]; then
    cat "$FOCUSD_ADDITIONS" >> "$TEMP_HOSTS"
fi

# Get original permissions
if [ -f "$HOSTS_FILE" ]; then
    PERMS=$(stat -c "%a" "$HOSTS_FILE")
    OWNER=$(stat -c "%U:%G" "$HOSTS_FILE")
else
    PERMS="644"
    OWNER="root:root"
fi

# Atomically replace /etc/hosts
mv "$TEMP_HOSTS" "$HOSTS_FILE"
chmod "$PERMS" "$HOSTS_FILE"
chown "$OWNER" "$HOSTS_FILE"

echo "Successfully merged /etc/hosts"
