{
  inputs,
  pkgs,
  system,
  prev,
  ...
}:
{
  _2048 = pkgs.callPackage ./2048 { };
  maple-mono-custom = pkgs.callPackage ./maple-mono { inherit inputs; };
  focusd = pkgs.callPackage ./focusd { focusdSrc = inputs.focusd; };
  thinky = pkgs.callPackage ./thinky { };
  python312Packages = prev.python312Packages.overrideScope (finalPy: prevPy: {
    jaraco-test = prevPy.jaraco-test.overridePythonAttrs (_old: {
      doCheck = false;
    });
  });
  firebase-tools = prev.callPackage (prev.path + "/pkgs/by-name/fi/firebase-tools/package.nix") {
    buildNpmPackage = prev.buildNpmPackage.override { nodejs = prev.nodejs_20; };
  };
  alvr = prev.alvr.overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + ''
        substituteInPlace alvr/server_openvr/cpp/platform/linux/EncodePipelineVAAPI.cpp \
          --replace 'FF_PROFILE_H264_BASELINE' 'AV_PROFILE_H264_BASELINE' \
          --replace 'FF_PROFILE_H264_MAIN' 'AV_PROFILE_H264_MAIN' \
          --replace 'FF_PROFILE_H264_HIGH' 'AV_PROFILE_H264_HIGH' \
          --replace 'FF_PROFILE_HEVC_MAIN_10' 'AV_PROFILE_HEVC_MAIN_10' \
          --replace 'FF_PROFILE_HEVC_MAIN' 'AV_PROFILE_HEVC_MAIN' \
          --replace 'FF_PROFILE_AV1_MAIN' 'AV_PROFILE_AV1_MAIN'
      '';
  });
  wf-recorder = prev.wf-recorder.overrideAttrs (old: rec {
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
