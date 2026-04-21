{ lib
, appimageTools
}:

let
  # Local release info is written by the electron repo's release:local script.
  # The file is staged so flake evaluation sees the new AppImage store path.
  releaseInfo = import ./release.nix;

  pname = "thinky";
  version = releaseInfo.version;

  # Default fractional scale so the Electron UI isn't microscopic on HiDPI setups.
  # Hyprland doesn't support per-window scaling, so we force the app to draw larger.
  scaleFactor = "3";

  src = releaseInfo.storePath;

  # Extract AppImage contents for desktop file and icons
  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  passthru = {
    appimageStorePath = toString src;
  };

  # This script is sourced inside the FHS env before running the AppImage.
  # We keep it simple to avoid ${...} conflicts with Nix interpolation.
  profile = ''
    export ELECTRON_FORCE_DEVICE_SCALE_FACTOR=${scaleFactor}
  '';

  extraInstallCommands = ''
    # Install desktop file if it exists
    if [ -f "${appimageContents}/thinky.desktop" ]; then
      install -m 444 -D "${appimageContents}/thinky.desktop" \
        "$out/share/applications/thinky.desktop"

      # Point Exec to the wrapped binary name "thinky" (the FHS wrapper),
      # instead of the upstream "AppRun".
      substituteInPlace "$out/share/applications/thinky.desktop" \
        --replace-fail 'Exec=AppRun' 'Exec=thinky' || true
    fi

    # Install icons from standard location
    if [ -d "${appimageContents}/usr/share/icons" ]; then
      cp -r "${appimageContents}/usr/share/icons" "$out/share/"
    else
      # Fallback: look for direct PNG icon
      for icon in ${appimageContents}/*.png; do
        if [ -f "$icon" ]; then
          mkdir -p "$out/share/icons/hicolor/512x512/apps"
          cp "$icon" "$out/share/icons/hicolor/512x512/apps/thinky.png"
          break
        fi
      done
    fi
  '';

  meta = with lib; {
    description = "Document annotation and ideation tool";
    homepage = "https://www.thinky.dev";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "thinky";
  };
}
