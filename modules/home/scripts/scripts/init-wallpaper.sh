#!/usr/bin/env bash

# Wallpaper configuration
WP_DIR="${HOME}/nixos-config/wallpapers"
WP_LEFT="Portrait/red4.jpg"
WP_RIGHT="red3.jpg"

# Start swww daemon if not running
if ! pgrep -x swww-daemon > /dev/null; then
    swww-daemon --no-cache &

    # Wait until the daemon is ready
    while ! swww query > /dev/null 2>&1; do
        sleep 0.1
    done
fi

# Detect hostname to determine monitor setup
HOSTNAME=$(hostname)

if [ "$HOSTNAME" = "desktop" ]; then
    # Desktop: Set per-monitor wallpapers
    swww img -t none --outputs DP-1 "${WP_DIR}/${WP_LEFT}" &
    swww img -t none --outputs DP-2 "${WP_DIR}/${WP_RIGHT}" &
else
    # Laptop or other: Set single wallpaper
    swww img -t none "${WP_DIR}/${WP_RIGHT}" &
fi
