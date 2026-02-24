{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ## Browser
    google-chrome

    ## Multimedia
    audacity
    gimp
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
    anki
    # calibre  # Temporarily disabled due to CUDA/PyTorch download issues
    foliate
    libreoffice
    gnome-calculator
    thinky

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
