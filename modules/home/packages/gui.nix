{ pkgs, lib, ... }:
let
  thinkyAppImagePath = "/home/zac/development/clojure/owl/electron/dist/thinky.AppImage";
  hasThinkyAppImage = builtins.pathExists thinkyAppImagePath;
in
{
  warnings = lib.optional (!hasThinkyAppImage) ''
    Skipping Thinky package: missing ${thinkyAppImagePath}.
    Build it with `npm run dist:linux` in ~/development/clojure/owl/electron,
    or place the AppImage there and run `thinky-hash`.
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
    ++ lib.optional hasThinkyAppImage thinky
    ++ [
      ## Utility
      dconf-editor
      gnome-disk-utility
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
}
