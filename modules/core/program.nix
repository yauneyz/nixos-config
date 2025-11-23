{ pkgs, ... }:
{
  programs = {
    dconf.enable = true;
    zsh.enable = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      # pinentryFlavor = "";
    };

    nix-ld.enable = true;
    nix-ld.libraries = with pkgs; [
      expat
      libgbm
      libxkbcommon
      gtk3
      gdk-pixbuf
      pango
      cairo
      glib
      nss
      nspr
      atk
      at-spi2-atk
      libnotify
      libdrm
      mesa
      libxshmfence
      xorg.libxcb
      xorg.libX11
      xorg.libXdamage
      xorg.libXfixes
      xorg.libXcomposite
      xorg.libXrandr
      xorg.libXcursor
      xorg.libXi
      xorg.libXtst
      xorg.libXext
      xorg.libXrender
      xorg.libXScrnSaver
      dbus
      cups
      alsa-lib
      libpulseaudio
    ];
  };
}
