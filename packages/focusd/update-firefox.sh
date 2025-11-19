#!/usr/bin/env bash
# NixOS helper script to update Firefox DoH exclusions
# This script is called by focusd when enabling/disabling profiles

set -euo pipefail

STATE_FILE="/var/lib/focusd/firefox-excluded-domains"
FIREFOX_PREF_DIR="/etc/firefox/pref"
FIREFOX_PREF_FILE="${FIREFOX_PREF_DIR}/focusd.js"

# Ensure Firefox preference directory exists
mkdir -p "$FIREFOX_PREF_DIR"

# If state file doesn't exist or is empty, remove the preference file
if [ ! -f "$STATE_FILE" ] || [ ! -s "$STATE_FILE" ]; then
    rm -f "$FIREFOX_PREF_FILE"
    echo "Firefox DoH exclusions disabled (no domains)"
    exit 0
fi

# Read domains from state file and convert to comma-separated list
DOMAINS=$(cat "$STATE_FILE" | tr '\n' ',' | sed 's/,$//')

if [ -z "$DOMAINS" ]; then
    rm -f "$FIREFOX_PREF_FILE"
    echo "Firefox DoH exclusions disabled (empty)"
    exit 0
fi

# Count domains for logging
DOMAIN_COUNT=$(cat "$STATE_FILE" | wc -l)

# Write Firefox preference file
cat > "$FIREFOX_PREF_FILE" << EOF
// focusd DNS-over-HTTPS exclusions
// Generated automatically by NixOS - do not edit manually
// ${DOMAIN_COUNT} domains excluded from DoH

// Disable DoH for blocked domains so DNS sinkhole works
pref("network.trr.excluded-domains", "${DOMAINS}");
EOF

echo "Firefox DoH exclusions updated: ${DOMAIN_COUNT} domains"
