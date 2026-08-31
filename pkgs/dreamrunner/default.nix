{
  lib,
  stdenvNoCC,
  runtimeShell,
  makeWrapper,
  cargo,
  rustc,
  entr,
  ffmpeg,
  findutils,
  releaseHost ? "desktop",
}:

let
  releaseInfo = import ./release.nix { host = releaseHost; };
  sourceAvailable = (releaseInfo.available or (releaseInfo ? storePath)) && (releaseInfo ? storePath);
  runtimePath = lib.makeBinPath [
    cargo
    rustc
    entr
    ffmpeg
    findutils
  ];

  unavailablePackage = stdenvNoCC.mkDerivation {
    pname = "dreamrunner";
    version = "unavailable";
    dontUnpack = true;
    installPhase = ''
      mkdir -p "$out"
    '';
    passthru = {
      releaseAvailable = false;
      inherit releaseHost;
    };
    meta = with lib; {
      description = "Deterministic endless-runner footage renderer";
      license = licenses.mit;
      platforms = platforms.linux;
      mainProgram = "dreamrunner";
      broken = true;
    };
  };
in
if !sourceAvailable then
  unavailablePackage
else
  stdenvNoCC.mkDerivation {
    pname = "dreamrunner";
    inherit (releaseInfo) version;
    dontUnpack = true;
    nativeBuildInputs = [ makeWrapper ];

    installPhase = ''
      runHook preInstall
      install -m 755 -D ${releaseInfo.storePath} "$out/libexec/dreamrunner"
      makeWrapper "$out/libexec/dreamrunner" "$out/bin/dreamrunner-core" \
        --prefix PATH : ${lib.makeBinPath [ ffmpeg ]}

      cat > "$out/bin/dreamrunner" <<'EOF'
      #!${runtimeShell}
      set -uo pipefail

      project_dir="''${DREAMRUNNER_DIR:-$HOME/development/dreamrunner}"

      if (( $# > 0 )) && [[ "$1" != "serve" ]]; then
        exec @out@/bin/dreamrunner-core "$@"
      fi

      if (( $# > 0 )); then
        shift
      fi

      if [[ ! -f "$project_dir/Cargo.toml" ]]; then
        echo "Dreamrunner checkout not found at $project_dir; using the installed release." >&2
        echo "Set DREAMRUNNER_DIR to override the development checkout." >&2
        exec @out@/bin/dreamrunner-core serve "$@"
      fi

      export PATH="@runtimePath@:$PATH"
      cd "$project_dir"
      echo "DREAMRUNNER hot reload: $project_dir"
      echo "Studio defaults to http://127.0.0.1:3000"

      watch_files() {
        find src web -type f -print
        printf '%s\n' Cargo.toml Cargo.lock
      }

      while true; do
        set +e
        watch_files | entr -d -r cargo run --locked --offline -- serve "$@"
        status=$?
        set -e
        if [[ $status -eq 2 ]]; then
          continue
        fi
        exit "$status"
      done
      EOF

      substituteInPlace "$out/bin/dreamrunner" \
        --replace-fail '@out@' "$out" \
        --replace-fail '@runtimePath@' '${runtimePath}'
      chmod 755 "$out/bin/dreamrunner"
      runHook postInstall
    '';

    passthru = {
      releaseAvailable = true;
      releaseStorePath = toString releaseInfo.storePath;
      inherit releaseHost;
    };

    meta = with lib; {
      description = "Deterministic endless-runner footage renderer with a hot-reload studio";
      license = licenses.mit;
      platforms = platforms.linux;
      mainProgram = "dreamrunner";
    };
  }
