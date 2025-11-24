{ lib
, appimageTools
}:

let
  pname = "thinky";
  version = "1.0.14";

  # Reference the AppImage in this directory
  # (AppImage should be placed here by build scripts)
  src = ./Thinky-1.0.14.AppImage;

  # Extract AppImage contents for desktop file and icons
  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    # Install desktop file if it exists
    if [ -f ${appimageContents}/thinky.desktop ]; then
      install -m 444 -D ${appimageContents}/thinky.desktop \
        $out/share/applications/thinky.desktop
      substituteInPlace $out/share/applications/thinky.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=thinky' || true
    fi

    # Install icons from standard location
    if [ -d ${appimageContents}/usr/share/icons ]; then
      cp -r ${appimageContents}/usr/share/icons $out/share/
    else
      # Fallback: look for direct PNG icon
      for icon in ${appimageContents}/*.png; do
        if [ -f "$icon" ]; then
          mkdir -p $out/share/icons/hicolor/512x512/apps
          cp "$icon" $out/share/icons/hicolor/512x512/apps/thinky.png
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
