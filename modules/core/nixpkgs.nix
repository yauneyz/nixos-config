{ pkgs, inputs, host, ... }:
{
  nixpkgs = {
    config = {
      allowBroken = true;  # Allow broken packages (needed for vLLM/flashinfer)
			cudaSupport = (host == "desktop");  # Uncomment to enable CUDA on desktop (~2hr initial build)
    };

    overlays = [
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
