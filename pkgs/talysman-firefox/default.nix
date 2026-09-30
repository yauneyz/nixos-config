{ lib
, stdenvNoCC
, unzip
, releaseHost ? "desktop"
}:

let
  # Written per host by the Talysman source repo's `pnpm run release:local`, which adds
  # the freshly built Firefox package (apps/extension/dist/talysman-firefox-<v>.zip) to
  # the store. The host file is staged so flake evaluation sees it.
  releaseInfo = import ./release.nix { host = releaseHost; };
  available = (releaseInfo.available or true) && (releaseInfo ? src);

  # Firefox's application ID; extensions dirs are keyed by it.
  firefoxAppId = "{ec8030f7-c20a-464f-9b0e-13a3a9e97384}";
in
stdenvNoCC.mkDerivation {
  pname = "talysman-firefox-extension";
  inherit (releaseInfo) version;

  src = if available then releaseInfo.src else null;
  dontUnpack = true;
  nativeBuildInputs = [ unzip ];

  # Unpacked, not an .xpi: Firefox only notices a changed <id>.xpi by its path and mtime,
  # both constant for a store symlink. A profile entry named exactly <id> that symlinks
  # to a directory is resolved to its target, so each rebuild's new store path counts
  # as an update. (Unsigned — relies on Developer Edition's signature override.)
  installPhase = lib.optionalString available ''
    dir="$out/share/mozilla/extensions/${firefoxAppId}/${releaseInfo.addonId}"
    mkdir -p "$dir"
    unzip -q "$src" -d "$dir"
  '' + lib.optionalString (!available) ''
    mkdir -p "$out"
  '';

  passthru = {
    inherit available releaseHost;
    addonId = releaseInfo.addonId or null;
    extensionDir =
      if available
      then "share/mozilla/extensions/${firefoxAppId}/${releaseInfo.addonId}"
      else null;
  };

  meta = with lib; {
    description = "Talysman browser extension (local unsigned Firefox build)";
    homepage = "https://talysman.app";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
