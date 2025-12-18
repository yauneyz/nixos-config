#!/usr/bin/env bash
# discover_geometry.sh
# Select a rectangle on the screen and report its geometry.

set -euo pipefail

is_wayland() {
  [[ ${XDG_SESSION_TYPE:-} == "wayland" || -n ${WAYLAND_DISPLAY:-} ]]
}

restore_xray=""
cleanup() {
  if [[ -n $restore_xray ]]; then
    hyprctl keyword decoration:blur:xray "$restore_xray" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

selector=""

if is_wayland && command -v slurp >/dev/null 2>&1; then
  selector="slurp"
elif command -v slop >/dev/null 2>&1; then
  selector="slop"
else
  echo "Error: neither 'slurp' (Wayland) nor 'slop' (X11) is available in PATH." >&2
  exit 1
fi

# Hyprland renders blur overlays with an "xray" effect that keeps windows visible.
# Temporarily turning xray off prevents the selection overlay from making
# everything look transparent.
if command -v hyprctl >/dev/null 2>&1; then
  if hyprctl getoption decoration:blur:xray 2>/dev/null | grep -q "int: 1"; then
    restore_xray="true"
    hyprctl keyword decoration:blur:xray false >/dev/null 2>&1 || restore_xray=""
  fi
fi

echo "👉 Drag a box on the screen to select your region..."

if [[ $selector == "slurp" ]]; then
  GEOM=$(slurp -f "%x %y %w %h")
  read -r X Y WIDTH HEIGHT <<< "$GEOM"
else
  GEOM=$(slop -f "%wx%h+%x+%y")
  WIDTH=$(echo "$GEOM" | cut -d'x' -f1)
  HEIGHT=$(echo "$GEOM" | cut -d'x' -f2 | cut -d'+' -f1)
  X=$(echo "$GEOM" | cut -d'+' -f2)
  Y=$(echo "$GEOM" | cut -d'+' -f3)
fi

echo
echo "📏 Geometry summary:"
echo "  Left:   $X"
echo "  Top:    $Y"
echo "  Width:  $WIDTH"
echo "  Height: $HEIGHT"
echo
echo "✅ maim geometry format:"
echo "  ${WIDTH}x${HEIGHT}+${X}+${Y}"
