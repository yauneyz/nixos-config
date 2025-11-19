{ pkgs, inputs, ... }:
{
  nixpkgs = {
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
      inputs.nur.overlays.default
    ];
  };
}
