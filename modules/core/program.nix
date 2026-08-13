{ pkgs, lib, ... }:
{
  # Environment variables for AppImage support
  environment.sessionVariables = {
    XDG_DATA_DIRS = lib.mkAfter [
      "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
      "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
    ];
  };

  # Transparently run Windows .exe binaries through Wine (kernel binfmt_misc).
  # electron-builder's Azure Trusted Signing cross-sign path (pwsh's Invoke-TrustedSigning
  # module, snorlax release:upload:win) shells out to signtool.exe directly rather than via
  # `wine signtool.exe`, so this registration is required for cross-signing Windows
  # installers from Linux to work at all.
  boot.binfmt.emulatedSystems = [ "x86_64-windows" ];

  programs = {
    dconf.enable = true;
    gpu-screen-recorder.enable = true;
    zsh.enable = true;
    appimage = {
      enable = true;
      binfmt = true;
    };

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      # pinentryFlavor = "";
    };

    nix-ld.enable = true;
    nix-ld.libraries = with pkgs; [
      # C/C++ standard library for Python packages with native extensions
      stdenv.cc.cc
      libglvnd
      expat
      libgbm
      libxkbcommon
      gtk3
      gsettings-desktop-schemas
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
      libxcb
      libx11
      libxdamage
      libxfixes
      libxcomposite
      libxrandr
      libxcursor
      libxi
      libxtst
      libxext
      libxrender
      libxscrnsaver
      dbus
      cups
      alsa-lib
      libpulseaudio
      libxcrypt-legacy
      libcap
      fuse # Provides libfuse.so.2 required by some AppImage runtimes
    ];
  };
}
