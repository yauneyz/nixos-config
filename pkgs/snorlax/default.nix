{ lib
, appimageTools
}:

let
  # Local release info is written by the snorlax repo's `pnpm run release:local`.
  # That script builds the AppImage, adds it to /nix/store, and stages this file so
  # flake evaluation sees the new version/store path on the next rebuild.
  releaseInfo = import ./release.nix;

  pname = "snorlax";
  version = releaseInfo.version;

  # Force a larger device scale so the Electron UI isn't microscopic on HiDPI setups
  # (Hyprland doesn't do per-window scaling), matching how thinky is handled.
  scaleFactor = "3";

  src = releaseInfo.storePath;

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  passthru = {
    # Forcing this attr is how modules detect whether a built AppImage is available
    # (see modules/home/packages/gui.nix). Fails to evaluate when release.nix is the
    # placeholder, so the package is skipped with a warning instead of erroring.
    appimageStorePath = toString src;
  };

  # Sourced inside the FHS env before the AppImage runs.
  profile = ''
    export ELECTRON_FORCE_DEVICE_SCALE_FACTOR=${scaleFactor}
  '';

  extraInstallCommands = ''
    # Install the desktop file (electron-builder names it after the executable).
    for desktop in ${appimageContents}/*.desktop; do
      if [ -f "$desktop" ]; then
        install -m 444 -D "$desktop" "$out/share/applications/snorlax.desktop"
        # Point Exec at the wrapped FHS binary name instead of the upstream AppRun.
        substituteInPlace "$out/share/applications/snorlax.desktop" \
          --replace-fail 'Exec=AppRun' 'Exec=snorlax' || true
        break
      fi
    done

    # Install icons.
    if [ -d "${appimageContents}/usr/share/icons" ]; then
      cp -r "${appimageContents}/usr/share/icons" "$out/share/"
    else
      for icon in ${appimageContents}/*.png; do
        if [ -f "$icon" ]; then
          mkdir -p "$out/share/icons/hicolor/512x512/apps"
          cp "$icon" "$out/share/icons/hicolor/512x512/apps/snorlax.png"
          break
        fi
      done
    fi
  '';

  meta = with lib; {
    description = "FocusLock (snorlax) distraction-blocker desktop UI";
    homepage = "https://focuslock.app";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "snorlax";
  };
}
