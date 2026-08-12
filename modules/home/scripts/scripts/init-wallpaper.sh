#!/usr/bin/env bash

# Wallpaper configuration
WP_DIR="${HOME}/nixos-config/wallpapers"
WP_LEFT="portrait/cosmic-milky-way-blue.jpg"
WP_RIGHT="cosmic-nebula-blue.jpg"

# Query the socket directly: the daemon's process name is not stable across
# awww versions, while a successful query proves the live instance is usable.
if ! awww query > /dev/null 2>&1; then
    awww-daemon --no-cache &

    # Wait until the daemon is ready
    while ! awww query > /dev/null 2>&1; do
        sleep 0.1
    done
fi

# Detect hostname to determine monitor setup
HOSTNAME=$(hostname)

if [ "$HOSTNAME" = "desktop" ]; then
    # Desktop: Set per-monitor wallpapers
    awww img -t none --outputs DP-1 "${WP_DIR}/${WP_LEFT}" &
    awww img -t none --outputs DP-2 "${WP_DIR}/${WP_RIGHT}" &
else
    # Laptop or other: Set single wallpaper
    awww img -t none "${WP_DIR}/${WP_RIGHT}" &
fi
