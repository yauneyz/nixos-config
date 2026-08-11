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

        # These packages are not currently available from cache for the pinned
        # nixos-unstable revision. Keep rebuilds practical by skipping their
        # large/flaky upstream suites while retaining build and import checks.
        poetry = prev.poetry.python.pkgs.toPythonApplication (
          prev.poetry.python.pkgs.poetry.overridePythonAttrs {
            doCheck = false;
            doInstallCheck = false;
          }
        );

        # python-lsp-black's tests still import pkg_resources, which was removed
        # from setuptools 82. The runtime import check still runs.
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (_python-final: python-prev: {
            python-lsp-server = python-prev.python-lsp-server.overridePythonAttrs {
              # Its full suite pulls every optional linter, including Pylint's
              # SciPy dependency. The runtime import check still runs.
              doCheck = false;
            };
            pylsp-mypy = python-prev.pylsp-mypy.overridePythonAttrs {
              # Its tests still configure mypy for unsupported Python 3.9.
              doCheck = false;
            };
            python-lsp-black = python-prev.python-lsp-black.overridePythonAttrs {
              doCheck = false;
            };
            python-lsp-ruff = python-prev.python-lsp-ruff.overridePythonAttrs (old: {
              # Ruff 0.16 intentionally removed E402 from its default rule set,
              # but python-lsp-ruff 2.3.1 still has two tests that assume it is
              # enabled by default. Keep the other 12 tests and runtime/import
              # checks while upstream catches up with Ruff's new defaults.
              disabledTests = (old.disabledTests or [ ]) ++ [
                "test_ruff_settings"
                "test_notebook_input"
              ];
            });
          })
        ];
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
