
# Launch Breath of the Wild in VR through BetterVR, ALVR and SteamVR.
#
# BetterVR's graphic packs and settings break flat play, so this links them in
# and swaps to a separate VR settings profile only for the VR session.
#
# Overrides: BOTW_PATH (game folder or .rpx), BOTW_VR_FRAME_STATS=1,
#            BOTW_VR_MIRROR=1 (draw the right eye into Cemu's window).

cemu_config="${XDG_CONFIG_HOME:-$HOME/.config}/Cemu"
cemu_data="${XDG_DATA_HOME:-$HOME/.local/share}/Cemu"
packs="$cemu_data/graphicPacks"
settings="$cemu_config/settings.xml"
flat_settings="$cemu_config/settings.flat.xml"
vr_settings="$cemu_config/settings.bettervr.xml"
botw="${BOTW_PATH:-$HOME/Games/Wii-U/The Legend of Zelda_ Breath of the Wild/base}"
pack_names=(BreathOfTheWild_BetterVR BreathOfTheWild_BetterVR_Graphics)

log() { printf '[botw-vr] %s\n' "$*" >&2; }

restore_flat() {
  for name in "${pack_names[@]}"; do
    [[ -L "$packs/$name" ]] && rm -f "$packs/$name"
  done
  if [[ -f "$flat_settings" ]]; then
    # Keep in-game VR tweaks for next time, then put the flat profile back.
    [[ -f "$settings" ]] && cp -f "$settings" "$vr_settings"
    mv -f "$flat_settings" "$settings"
    log "Restored flat Cemu settings."
  fi
}

if pgrep -f 'bin/(\.Cemu-wrapped|Cemu)( |$)' >/dev/null; then
  log "Cemu is already running; close it first."
  exit 1
fi

# A crashed session can leave the VR profile in place.
restore_flat

[[ -e "$botw" ]] || { log "Game not found at $botw (set BOTW_PATH)."; exit 1; }
[[ -f "$settings" ]] || { log "Run Cemu once normally to create $settings."; exit 1; }

if ! pgrep -x vrserver >/dev/null; then
  log "SteamVR is not running. Starting it through Steam (uses the steamvr-alvr launch option)..."
  log "Tip: open alvr_dashboard first and connect the Quest 3."
  steam steam://run/250820 >/dev/null 2>&1 &
  for _ in $(seq 1 120); do
    pgrep -x vrserver >/dev/null && break
    sleep 1
  done
  pgrep -x vrserver >/dev/null || { log "SteamVR did not start."; exit 1; }
  sleep 5
fi

trap restore_flat EXIT INT TERM

for name in "${pack_names[@]}"; do
  ln -sfn "$BETTERVR_LAYER/share/bettervr/graphicPacks/$name" "$packs/$name"
done

cp -f "$settings" "$flat_settings"
if [[ ! -f "$vr_settings" ]]; then
  log "Creating VR settings profile at $vr_settings."
  python3 "$BETTERVR_PROFILE_TOOL" seed "$flat_settings" "$vr_settings" \
    "$BETTERVR_LAYER/share/bettervr/graphicPacks/BreathOfTheWild_BetterVR_Graphics/rules.txt"
fi
python3 "$BETTERVR_PROFILE_TOOL" enforce "$vr_settings"
cp -f "$vr_settings" "$settings"

export VK_ADD_LAYER_PATH="$BETTERVR_LAYER/share/vulkan/explicit_layer.d${VK_ADD_LAYER_PATH:+:$VK_ADD_LAYER_PATH}"
export VK_INSTANCE_LAYERS="VK_LAYER_CREMENTIF_bettervr${VK_INSTANCE_LAYERS:+:$VK_INSTANCE_LAYERS}"
export ENABLE_BETTERVR_MOD=1
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$BETTERVR_VRCLIENT_LIBS"
[[ "${BOTW_VR_FRAME_STATS:-0}" == 1 ]] && export BETTERVR_LINUX_FRAME_STATS=1
if [[ "${BOTW_VR_MIRROR:-0}" == 1 ]]; then
  export BETTERVR_DESKTOP_MIRROR=1 BETTERVR_DESKTOP_MIRROR_EYE=right
fi

log "Launching Cemu with BetterVR. Hold X on the left controller for the BetterVR menu."
set +e
"$BETTERVR_CEMU" -g "$botw" "$@"
status=$?
set -e
log "Cemu exited with status $status."
exit "$status"
