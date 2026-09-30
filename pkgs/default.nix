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
  chatgpt-linux = pkgs.callPackage ./chatgpt-linux { };
  claude-desktop = pkgs.callPackage ./claude-desktop { };
  dreamrunner = pkgs.callPackage ./dreamrunner { releaseHost = host; };
  maple-mono-custom = pkgs.callPackage ./maple-mono { inherit inputs; };
  readfence = pkgs.callPackage ./readfence { };
  screenplain = pkgs.callPackage ./screenplain {
    python3Packages = pkgs.python312Packages;
  };
  talysman = pkgs.callPackage ./snorlax { releaseHost = host; };
  talysman-daemon = pkgs.callPackage ./snorlax-daemon { snorlaxSrc = inputs.snorlax; };
  talysman-firefox = pkgs.callPackage ./talysman-firefox { releaseHost = host; };
  snorlax = talysman;
  snorlax-daemon = talysman-daemon;
  thinky = pkgs.callPackage ./thinky { releaseHost = host; };
  python312Packages = prev.python312Packages.overrideScope (
    finalPy: prevPy: {
      jaraco-test = prevPy.jaraco-test.overridePythonAttrs (_old: {
        doCheck = false;
      });
      pipx = prevPy.pipx.overridePythonAttrs (_old: {
        doCheck = false;
      });
    }
  );
  firebase-tools = prev.callPackage (prev.path + "/pkgs/by-name/fi/firebase-tools/package.nix") {
    buildNpmPackage = prev.buildNpmPackage.override { nodejs = prev.nodejs_20; };
  };
  # ffmpeg 8+ removed the same deprecated AVCodec fields (pix_fmts,
  # sample_fmts) that simplescreenrecorder's AVWrapper.cpp reads directly.
  # Same fix as wf-recorder below: pin to ffmpeg_7 until upstream migrates.
  simplescreenrecorder = prev.simplescreenrecorder.override { ffmpeg = prev.ffmpeg_7; };

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
