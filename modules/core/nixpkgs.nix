{
  pkgs,
  inputs,
  host,
  ...
}:
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
      inputs.fenix.overlays.default
      inputs.claude-code.overlays.default

      # Home Manager still references deprecated xorg aliases in some modules.
      (final: prev: {
        xorg = prev.xorg // {
          xrdb = prev.xrdb;
          lndir = prev.lndir;
        };

        # Zotero 10.0.2 targets Firefox ESR 140, but nixpkgs builds it against
        # ESR 153, which moved several actors into `JSWINDOWACTORS.<name> = {}`
        # assignments, split aboutaddons.js into ES modules, and dropped
        # search-textbox. Retarget fetch_xulrunner's omni edits so it doesn't
        # abort on patterns that no longer match.
        zotero = prev.zotero.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./patches/zotero-firefox-esr-153.patch ];
        });

      })
      (
        final: prev:
        (import ../../pkgs {
          inherit host inputs;
          pkgs = final;
          inherit prev;
          inherit (prev) system;
        })
      )
    ];
  };
}
