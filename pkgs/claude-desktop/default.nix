{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
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
  libcap_ng,
  libseccomp,
  libsecret,
  libuuid,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  libxtst,
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
  pname = "claude-desktop";
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
    cairo
    cups
    dbus
    expat
    gtk3
    glib
    libdrm
    libgbm
    libGL
    libcap_ng
    libseccomp
    libsecret
    libuuid
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    libxtst
    nspr
    nss
    pango
    systemdLibs
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb --fsys-tarfile "$src" | tar --extract
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/lib" "$out/share"
    cp -r usr/lib/claude-desktop "$out/lib/"
    cp -r usr/share/applications usr/share/icons "$out/share/"

    # A per-user Nix package cannot install Electron's setuid sandbox helper.
    # Keep the helper non-setuid and use Electron's namespace-free fallback.
    chmod 0755 "$out/lib/claude-desktop/chrome-sandbox"
    makeWrapper "$out/lib/claude-desktop/claude-desktop" "$out/bin/claude-desktop" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
      --add-flags "--no-sandbox --disable-gpu-sandbox" \
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
    description = "Official Claude desktop app for Linux";
    homepage = "https://code.claude.com/docs/en/desktop-linux";
    license = lib.licenses.unfree;
    mainProgram = "claude-desktop";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
