{
  lib,
  stdenvNoCC,
  fetchurl,
  buildFHSEnv,
  dpkg,
  writeShellScript,
}:

let
  source = import ./source.nix;

  # The bundled Electron binary must NOT be patched: rewriting its ELF headers
  # makes Node's diagnostic-report generator crash with SIGILL, which kills the
  # whole app as soon as the git repo watcher starts on an open project.
  # Run it inside an FHS sandbox instead, the way upstream ships it.
  unwrapped = stdenvNoCC.mkDerivation {
    pname = "chatgpt-linux-unwrapped";
    inherit (source) version;

    src = fetchurl source.src;

    nativeBuildInputs = [ dpkg ];

    dontPatchELF = true;
    dontStrip = true;

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb --fsys-tarfile "$src" | tar --extract
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/lib" "$out/share"
      cp -r usr/lib/chatgpt "$out/lib/"
      cp -r usr/share/applications usr/share/pixmaps "$out/share/"

      runHook postInstall
    '';
  };

  launcher = writeShellScript "chatgpt-launcher" ''
    exec "${unwrapped}/lib/chatgpt/ChatGPT" \
      ''${NIXOS_OZONE_WL:+''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}} \
      "$@"
  '';
in
buildFHSEnv {
  pname = "chatgpt";
  inherit (source) version;

  targetPkgs =
    pkgs:
    (with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      coreutils
      cups
      dbus
      dconf
      expat
      fontconfig
      freetype
      gdk-pixbuf
      git
      glib
      gsettings-desktop-schemas
      gtk3
      libdrm
      libgbm
      libGL
      libglvnd
      libnotify
      libpulseaudio
      libusb1
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxkbcommon
      libxrandr
      mesa
      nspr
      nss
      pango
      systemdLibs
      xdg-utils
    ])
    ++ [ pkgs.stdenv.cc.cc.lib ]
    ++ (with pkgs.xorg; [
      libXScrnSaver
      libXi
      libXrender
      libXtst
      libxshmfence
    ]);

  runScript = launcher;

  extraInstallCommands = ''
    mkdir -p "$out/share"
    cp -r "${unwrapped}/share/applications" "$out/share/"
    cp -r "${unwrapped}/share/pixmaps" "$out/share/"
  '';

  meta = {
    description = "Official ChatGPT desktop app for Linux";
    homepage = "https://learn.chatgpt.com/docs/linux/linux-app";
    license = lib.licenses.unfree;
    mainProgram = "chatgpt";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
