{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ## Multimedia
    audacity
    gimp
    media-downloader
    obs-studio
    pavucontrol
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
  ];
}
