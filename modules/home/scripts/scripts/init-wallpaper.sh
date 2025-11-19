#!/usr/bin/env bash

# Wallpaper paths (relative to nixos-config directory)
NIXOS_CONFIG="${HOME}/nixos-config"
WALLPAPER_LEFT="${NIXOS_CONFIG}/wallpapers/otherWallpaper/gruvbox/forest_road.jpg"
WALLPAPER_RIGHT="${NIXOS_CONFIG}/wallpapers/otherWallpaper/gruvbox/japanese_pedestrian_street.png"

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
    swww img -t none --outputs DP-1 "$WALLPAPER_LEFT" &
    swww img -t none --outputs DP-2 "$WALLPAPER_RIGHT" &
else
    # Laptop or other: Set single wallpaper
    swww img -t none "$WALLPAPER_RIGHT" &
fi
