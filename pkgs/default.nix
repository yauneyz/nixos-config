{
  host ? "desktop",
  inputs,
  pkgs,
  system,
  prev,
  ...
}:
rec {
  _2048 = pkgs.callPackage ./2048 { };
  botw-vr = pkgs.callPackage ./bettervr { };
  chatgpt-linux = pkgs.callPackage ./chatgpt-linux { };
  claude-desktop = pkgs.callPackage ./claude-desktop { };
  dreamrunner = pkgs.callPackage ./dreamrunner { releaseHost = host; };
  maple-mono-custom = pkgs.callPackage ./maple-mono { inherit inputs; };
  readfence = pkgs.callPackage ./readfence { };
  screenplain = pkgs.callPackage ./screenplain { };
  talysman = pkgs.callPackage ./snorlax { releaseHost = host; };
  talysman-daemon = pkgs.callPackage ./snorlax-daemon { snorlaxSrc = inputs.snorlax; };
  talysman-firefox = pkgs.callPackage ./talysman-firefox { releaseHost = host; };
  snorlax = talysman;
  snorlax-daemon = talysman-daemon;
  thinky = pkgs.callPackage ./thinky { releaseHost = host; };
  # Qt 6.12's generated QML lookup Type collides with extensions::Type when
  # this module's C++ files are combined into a unity translation unit.
  audacity = prev.audacity.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      echo 'set_target_properties(muse_extensions_qml PROPERTIES UNITY_BUILD OFF)' >> muse/framework/extensions/qml/Muse/Extensions/CMakeLists.txt
    '';
  });
  # Azure CLI's Fabric dependency requires Invoke < 3. Keep its Python
  # environment on the supported release until Fabric supports Invoke 3.
  azure-cli = prev.azure-cli.override {
    # Extending all of nixpkgs here reapplies this overlay, recursively
    # evaluating azure-cli until the evaluator exhausts memory. Compose the
    # pin into Python's overrides, including Azure's own package overrides.
    python3 = prev.lib.makeOverridable
      (args: prev.python3.override (args // {
        packageOverrides = prev.lib.composeExtensions
          (args.packageOverrides or (_: _: { }))
          (_: prevPython: {
            invoke = prevPython.invoke.overridePythonAttrs (old: rec {
              version = "2.2.1";
              src = pkgs.fetchPypi {
                pname = "invoke";
                inherit version;
                hash = "sha256-UVv0m0pIkyt5sCRZA0jaIvOcSULf+ZGtH7i4uuob5wc=";
              };
            });
          });
      }))
      { };
  };
  # ffmpeg 8+ removed the same deprecated AVCodec fields (pix_fmts,
  # sample_fmts) that simplescreenrecorder's AVWrapper.cpp reads directly.
  # Same fix as wf-recorder below: pin to ffmpeg_7 until upstream migrates.
  simplescreenrecorder = prev.simplescreenrecorder.override { ffmpeg = prev.ffmpeg_7; };

  # nixpkgs' default nodejs (24.x) is behind the October 21, 2026 security
  # release (CVE-2026-111497 Brotli OOB write, TLS hostname bypasses, ...).
  # The 24.22.1 bump is merged in staging but hasn't reached nixos-unstable.
  # Exposed as a separate attr so only our user packages rebuild, and it falls
  # back to the plain nixpkgs default once that catches up.
  # nixpkgs links node against system brotli, so the Brotli fix node vendors
  # (upstream 0ed4268a, which also adds a constant node_zlib.cc needs) has to
  # be applied to the brotli we hand it.
  nodejs-patched =
    if pkgs.lib.versionOlder prev.nodejs.version "24.22.1" then
      prev.nodejs_24.override {
        nodejs-slim = (prev.nodejs-slim_24.override {
          callPackage = fn: args: prev.callPackage fn (args // {
            brotli = prev.brotli.overrideAttrs (old: {
              patches = (old.patches or [ ]) ++ [
                (pkgs.fetchurl {
                  url = "https://github.com/google/brotli/commit/0ed4268a4401abcb4472096340477cf4af7d1a2b.patch?full_index=1";
                  hash = "sha256-1vliUJAAIj3vcGKVgim9CEV+XgMuftDR2U+3kLBUsfw=";
                })
              ];
            });
          });
        }).overrideAttrs (old: rec {
          version = "24.22.1";
          src = pkgs.fetchurl {
            url = "https://nodejs.org/dist/v${version}/node-v${version}.tar.xz";
            sha256 = "4f5379796280cdaeb0c2f358fd04b6a16cc4fb7dfa83b5a8c91a9d963b435231";
          };
        });
      }
    else
      prev.nodejs;

  wf-recorder =
    (prev.wf-recorder.override {
      # ffmpeg 8+ removed the deprecated AVCodec.sample_fmts field that
      # wf-recorder 0.6.0's frame-writer.cpp still reads directly, breaking
      # the build ("has no member named 'sample_fmts'"). Pin to ffmpeg_7
      # until upstream wf-recorder migrates to avcodec_get_supported_config.
      ffmpeg_8 = prev.ffmpeg_7;
    }).overrideAttrs
      (old: rec {
        version = "0.6.0";
        src = pkgs.fetchFromGitHub {
          owner = "ammen99";
          repo = "wf-recorder";
          rev = "v${version}";
          hash = "sha256-CY0pci2LNeQiojyeES5323tN3cYfS3m4pECK85fpn5I=";
        };
        # Remove old patches - they're already applied in 0.6.0
        patches = [ ];
      });
}
