{ pkgs, lib, ... }:
let
  hasThinky = pkgs.thinky.appimageAvailable or false;
  hasTalysman = pkgs.talysman.appimageAvailable or false;
  metabasePort = "3010";
  metabaseWrapped = pkgs.symlinkJoin {
    name = "metabase-wrapped";
    paths = [ pkgs.metabase ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/metabase \
        --set-default MB_JETTY_PORT ${metabasePort}
    '';
  };
in
{
  warnings = lib.optional (!hasThinky) ''
    Skipping Thinky package: AppImage source is unavailable.
    Rebuild it from the electron repo with `npm run release:local`
    (writes and stages pkgs/thinky/release.nix), then rebuild NixOS.
  '' ++ lib.optional (!hasTalysman) ''
    Skipping Talysman package: AppImage source is unavailable.
    Build it from the Talysman source repo with `talysman-dist` (pnpm run release:local)
    (writes and stages pkgs/snorlax/release.nix), then rebuild NixOS.
  '';

  home.packages = with pkgs;
    [
      ## Browser
      google-chrome

      ## Multimedia
      audacity
      easyeffects
      gimp
      gpu-screen-recorder
      gpu-screen-recorder-gtk
      loupe
      media-downloader
      obs-studio
      pavucontrol
      shotcut
      simplescreenrecorder
      wf-recorder   # Wayland screen recorder
      spotify
      soundwireserver
      video-trimmer

      ## Office
      (lib.getAttr "anki-bin" pkgs)
      # calibre  # Temporarily disabled due to CUDA/PyTorch download issues
      libreoffice
      gnome-calculator
      readfence
      typora
      zotero
    ]
    ++ lib.optional hasThinky thinky
    ++ lib.optional hasTalysman talysman
    ++ [
      ## Utility
      dconf-editor
      dbeaver-bin
      gnome-disk-utility
      metabaseWrapped
      qdirstat
      mission-center # GUI resources monitor
      overskride # Modern Bluetooth manager
      sillytavern
      zenity
      zoom-us

      ## Level editor
      ldtk
      tiled
    ];

  home.file.".local/share/applications/metabase.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Metabase
    Comment=Metabase on port ${metabasePort}
    Exec=metabase
    Terminal=true
    Categories=Office;Database;
    StartupNotify=true
  '';
}
