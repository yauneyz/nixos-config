{
  lib,
  appimageTools,
  fetchurl,
}:

let
  source = import ./source.nix;
  pname = "ltx-desktop";
  inherit (source) version;
  src = fetchurl source.src;
  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # On first launch the app downloads a ~10 GB relocatable Python env (CUDA
  # torch wheels) into its data dir and runs the backend from it inside this
  # FHS env, so the libs those wheels dlopen have to be present here.
  extraPkgs =
    pkgs: with pkgs; [
      stdenv.cc.cc.lib
      zlib
      libGL
      libglvnd
      glib
      vulkan-loader
      libxcrypt-legacy
    ];

  # CUDA wheels find libcuda through the host driver's stable runtime symlink.
  profile = ''
    export LD_LIBRARY_PATH="/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export ELECTRON_OZONE_PLATFORM_HINT=auto
  '';

  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/ltx-desktop.desktop \
      $out/share/applications/ltx-desktop.desktop
    substituteInPlace $out/share/applications/ltx-desktop.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=ltx-desktop'
    cp -r ${appimageContents}/usr/share/icons $out/share/
  '';

  meta = {
    description = "Open-source desktop app for local LTX video generation";
    homepage = "https://github.com/Lightricks/LTX-Desktop";
    license = lib.licenses.asl20;
    mainProgram = "ltx-desktop";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
