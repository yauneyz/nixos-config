{ lib
, appimageTools
, makeBinaryWrapper  # not used here, but harmless to leave
, requireFile
}:

let
  pname = "thinky";
  version = "1.0.14";

  # Default fractional scale so the Electron UI isn't microscopic on HiDPI setups.
  # Hyprland doesn't support per-window scaling, so we force the app to draw larger.
  scaleFactor = "3";

  # Use requireFile to reference AppImage from nix store
  # Add/update this hash with:
  # thinky-hash /path/to/thinky.AppImage
  src = requireFile {
    name = "thinky.AppImage";
    url = "https://www.thinky.dev";
    sha256 = "1azr90hgzgwghghh8c8dyj4vlkpnxqy201yl1r2pikyf9lid4n3y";
    message = ''
      The Thinky AppImage is not in the Nix store for this hash.
      Add it by running:
        thinky-hash /path/to/thinky.AppImage

      Or manually:
        nix-store --add-fixed sha256 /path/to/thinky.AppImage
    '';
  };
  srcStorePath = builtins.unsafeDiscardStringContext src.outPath;

  # Extract AppImage contents for desktop file and icons
  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # Expose the fixed-output source path so config can skip Thinky cleanly
  # when the AppImage has not been added to the store yet.
  passthru = {
    appimageStorePath = srcStorePath;
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
