{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "readfence";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "adamwhiles";
    repo = "readfence";
    rev = version;
    hash = "sha256-C9eH08IqPbXJ+ROykeDIyliQa/bmgcIl90i1qaTEvXY=";
  };

  cargoHash = "sha256-p05/6QSxao1ZnAdU9pZY2R2TUaKvOCQyFtdSMgHK/sE=";

  postInstall = ''
    install -Dm644 flatpak/com.readfence.Readfence.desktop \
      $out/share/applications/com.readfence.Readfence.desktop
    install -Dm644 assets/icon.png \
      $out/share/icons/hicolor/256x256/apps/com.readfence.Readfence.png
  '';

  meta = {
    description = "Clean, modern Markdown viewer";
    homepage = "https://readfence.com";
    changelog = "https://github.com/adamwhiles/readfence/blob/${version}/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "readfence";
    platforms = lib.platforms.linux;
  };
}
