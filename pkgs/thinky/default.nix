{ lib
, stdenv
, buildNpmPackage
, electron
, makeWrapper
, nodejs
, jre
, git
, clojure
, owlSrc ? null  # Source from flake input
}:

let
  # Pre-fetch Maven dependencies for shadow-cljs
  mavenDeps = stdenv.mkDerivation {
    name = "thinky-maven-deps";
    src = if owlSrc != null
      then "${owlSrc}/electron"
      else throw "owlSrc must be provided";

    nativeBuildInputs = [ clojure nodejs jre ];

    buildPhase = ''
      export HOME=$TMPDIR

      # Download all Clojure dependencies
      clojure -P -M:dev:shadow

      # Install npm dependencies to get shadow-cljs
      export npm_config_cache=$HOME/.npm
      npm install --legacy-peer-deps --no-audit --no-fund

      # Run shadow-cljs to trigger Maven dependency downloads
      # This will download all deps needed for actual compilation
      export ELECTRON_SKIP_BINARY_DOWNLOAD=1
      npx shadow-cljs classpath 2>/dev/null || true
      npx shadow-cljs compile --help 2>/dev/null || true
    '';

    installPhase = ''
      mkdir -p $out
      cp -r $HOME/.m2 $out/
      cp -r $HOME/.gitlibs $out/ 2>/dev/null || true
      cp -r $HOME/.clojure $out/ 2>/dev/null || true
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = lib.fakeHash;
  };
in
buildNpmPackage rec {
  pname = "thinky";
  version = "1.0.14";

  src = if owlSrc != null
    then "${owlSrc}/electron"
    else throw "owlSrc must be provided (pass from flake input)";

  # This hash will be automatically updated by update-hash.sh
  # To get the initial hash, set this to lib.fakeHash and run:
  # nix-build -E 'with import <nixpkgs> {}; callPackage ./pkgs/thinky {}'
  npmDepsHash = "sha256-LuS5CjLyO+KwgaUt7rMgUcSWyHoNOhqKqBQuikMjJwc=";

  # Handle peer dependency issues and allow cache writes
  npmFlags = [ "--legacy-peer-deps" ];
  makeCacheWritable = true;

  nativeBuildInputs = [
    nodejs
    makeWrapper
    jre  # Required for shadow-cljs (runs on JVM)
    git  # Required by some npm packages
    clojure  # Required for shadow-cljs
  ];

  # Don't run npm install, we'll use npm ci via npmDepsHash
  dontNpmBuild = true;

  # Skip electron binary download - we use the electron from nixpkgs
  ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  # Custom build phase
  buildPhase = ''
    runHook preBuild

    # Set up Maven local repository with pre-fetched dependencies
    export HOME=$TMPDIR
    mkdir -p $HOME/.m2
    cp -r ${mavenDeps}/.m2/* $HOME/.m2/ || true
    cp -r ${mavenDeps}/.gitlibs $HOME/ || true
    cp -r ${mavenDeps}/.clojure $HOME/ || true
    chmod -R +w $HOME/.m2 || true
    chmod -R +w $HOME/.gitlibs || true
    chmod -R +w $HOME/.clojure || true

    # Create Maven settings.xml to enforce offline mode
    cat > $HOME/.m2/settings.xml <<EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <settings>
      <localRepository>$HOME/.m2/repository</localRepository>
      <offline>true</offline>
    </settings>
    EOF

    # Configure JVM options for Clojure/shadow-cljs
    export MAVEN_OPTS="-Dmaven.repo.local=$HOME/.m2/repository"
    export CLJ_CONFIG=$HOME/.clojure
    export GITLIBS=$HOME/.gitlibs

    echo "Building CSS..."
    node scripts/build-css.js

    echo "Compiling ClojureScript with shadow-cljs..."
    # Run shadow-cljs with Maven repository configured
    npx shadow-cljs release main-prod renderer-prod

    echo "Packaging with electron-builder (unpacked only)..."
    npx electron-builder --linux --dir

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/thinky
    mkdir -p $out/bin

    # Copy the unpacked application
    cp -r dist/linux-unpacked/* $out/share/thinky/

    # Create wrapper script
    makeWrapper ${electron}/bin/electron $out/bin/thinky \
      --add-flags "$out/share/thinky/resources/app.asar" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}" \
      --set-default ELECTRON_IS_DEV 0

    # Install desktop entry if it exists
    if [ -f build/icons/icon.png ]; then
      mkdir -p $out/share/icons/hicolor/512x512/apps
      cp build/icons/icon.png $out/share/icons/hicolor/512x512/apps/thinky.png
    fi

    # Create desktop file
    mkdir -p $out/share/applications
    cat > $out/share/applications/thinky.desktop << EOF
[Desktop Entry]
Name=Thinky
Comment=Document annotation and ideation tool
Exec=$out/bin/thinky
Icon=thinky
Type=Application
Categories=Office;
EOF

    runHook postInstall
  '';

  # Metadata about the current build
  passthru = {
    updateScript = ./update-hash.sh;
  };

  meta = with lib; {
    description = "Document annotation and ideation tool";
    homepage = "https://www.thinky.dev";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "thinky";
  };
}
