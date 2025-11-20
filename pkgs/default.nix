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
  focusd = pkgs.callPackage ./focusd { };
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
}
