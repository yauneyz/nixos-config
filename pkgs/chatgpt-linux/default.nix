{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  coreutils,
  cups,
  dbus,
  dconf,
  expat,
  git,
  gsettings-desktop-schemas,
  gtk3,
  glib,
  libdrm,
  libgbm,
  libGL,
  libnotify,
  libusb1,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  nspr,
  nss,
  pango,
  systemdLibs,
  xdg-utils,
}:

let
  source = import ./source.nix;
in
stdenvNoCC.mkDerivation {
  pname = "chatgpt-linux";
  inherit (source) version;

  src = fetchurl source.src;

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    gtk3
    glib
    libdrm
    libgbm
    libGL
    libnotify
    libusb1
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    nspr
    nss
    pango
    systemdLibs
  ];

  # These shims integrate with Qt file dialogs only when a matching Qt runtime
  # is present. ChatGPT works without either optional library.
  autoPatchelfIgnoreMissingDeps = [
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
    "libQt6Core.so.6"
    "libQt6Gui.so.6"
    "libQt6Widgets.so.6"
    "libc.musl-x86_64.so.1"
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb --fsys-tarfile "$src" | tar --extract
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/lib" "$out/share"
    cp -r usr/lib/chatgpt "$out/lib/"
    cp -r usr/share/applications usr/share/pixmaps "$out/share/"

    makeWrapper "$out/lib/chatgpt/ChatGPT" "$out/bin/chatgpt" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
      --prefix PATH : "${
        lib.makeBinPath [
          coreutils
          git
          xdg-utils
        ]
      }" \
      --prefix XDG_DATA_DIRS : "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}" \
      --prefix XDG_DATA_DIRS : "${gtk3}/share/gsettings-schemas/${gtk3.name}" \
      --prefix GIO_EXTRA_MODULES : "${dconf.lib}/lib/gio/modules" \
      --set GDK_PIXBUF_MODULE_FILE "$GDK_PIXBUF_MODULE_FILE"

    runHook postInstall
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
