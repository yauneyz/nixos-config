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
      inputs.fenix.overlays.default
      inputs.claude-code.overlays.default

      # Home Manager still references deprecated xorg aliases in some modules.
      (final: prev: {
        xorg = prev.xorg // {
          xrdb = prev.xrdb;
          lndir = prev.lndir;
        };

        # python-lsp-black's tests still import pkg_resources, which was removed
        # from setuptools 82. The runtime import check still runs.
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (_python-final: python-prev: {
            pylsp-mypy = python-prev.pylsp-mypy.overridePythonAttrs {
              # Its tests still configure mypy for unsupported Python 3.9.
              doCheck = false;
            };
            python-lsp-black = python-prev.python-lsp-black.overridePythonAttrs {
              doCheck = false;
            };
          })
        ];
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
