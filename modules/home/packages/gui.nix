{ pkgs, lib, ... }:
let
  hasThinky = builtins.pathExists pkgs.thinky.appimageStorePath;
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
    Skipping Thinky package: AppImage is not available in the Nix store for the hash in pkgs/thinky/default.nix.
    Add/update it with `thinky-hash /path/to/thinky.AppImage` and rebuild.
  '';

  home.packages = with pkgs;
    [
      ## Browser
      google-chrome

      ## Multimedia
      audacity
      gimp
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
      vlc

      ## Office
      (lib.getAttr "anki-bin" pkgs)
      # calibre  # Temporarily disabled due to CUDA/PyTorch download issues
      foliate
      libreoffice
      gnome-calculator
    ]
    ++ lib.optional hasThinky thinky
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

      ## Emulators
      (symlinkJoin {
        name = "ryubing-wrapped";
        paths = [ ryubing ];
        buildInputs = [ makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/Ryujinx \
            --set GDK_BACKEND x11
        '';
      })
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
