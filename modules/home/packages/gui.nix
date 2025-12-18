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
    libreoffice
    gnome-calculator
    thinky

    ## Utility
    dconf-editor
    gnome-disk-utility
    mission-center # GUI resources monitor
    overskride # Modern Bluetooth manager
    zenity
    zoom-us

    ## Level editor
    ldtk
    tiled
  ];
}
