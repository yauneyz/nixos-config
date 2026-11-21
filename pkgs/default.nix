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
  comfyui-mcp = pkgs.callPackage ./comfyui-mcp { };
  dreamrunner = pkgs.callPackage ./dreamrunner { releaseHost = host; };
  ltx-desktop = pkgs.callPackage ./ltx-desktop { };
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
      (_old: rec {
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
