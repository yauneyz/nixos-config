{ pkgs, inputs, host, ... }:
{
  nixpkgs = {
    config = {
      allowBroken = true;  # Allow broken packages (needed for vLLM/flashinfer)
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
