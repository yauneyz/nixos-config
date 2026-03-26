{ pkgs, inputs, host, ... }:
{
  nixpkgs = {
    config = {
      # Keep this permissive for overlays that may track ahead of nixpkgs.
      allowBroken = true;
      # Keep CUDA disabled globally; enabling it here forces unrelated packages
      # (e.g. Firefox -> onnxruntime -> cutlass) into expensive CUDA builds.
      cudaSupport = false;
    };

    overlays = [
      # Home Manager still references deprecated xorg aliases in some modules.
      (final: prev: {
        xorg = prev.xorg // {
          xrdb = prev.xrdb;
          lndir = prev.lndir;
        };
      })
      (
        final: prev:
        (import ../../pkgs {
          inherit inputs;
          pkgs = final;
          inherit prev;
          inherit (prev) system;
        })
      )
    ];
  };
}
