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

        # buildRedistHook flattens propagatedBuildOutputs to a string for
        # _multioutPropagateDev, but stdenv now reads it with concatTo, so the
        # structuredAttrs array collapses to one bogus "include lib" output and
        # every CUDA redist fails in fixup. Drop the flattening and read the
        # array properly until nixpkgs reconciles the two.
        _cuda = prev._cuda.extend (
          _: cudaPrev: {
            extensions = cudaPrev.extensions ++ [
              (
                _: cudaPackagesPrev:
                let
                  patchedHook = final.runCommand "buildRedistHook.bash" { } ''
                    cp ${final.path}/pkgs/development/cuda-modules/buildRedist/buildRedistHook.bash $out
                    substituteInPlace $out \
                      --replace-fail 'preFixupHooks+=(fixupPropagatedBuildOutputsForMultipleOutputs)' "" \
                      --replace-fail 'for output in $propagatedBuildOutputs; do' \
                        'local -a cudaOutputs=(); concatTo cudaOutputs propagatedBuildOutputs; for output in "''${cudaOutputs[@]}"; do'
                  '';
                  swapHook =
                    input: if builtins.isPath input && baseNameOf input == "buildRedistHook.bash" then patchedHook else input;
                in
                {
                  buildRedist =
                    args:
                    (cudaPackagesPrev.buildRedist args).overrideAttrs (old: {
                      nativeBuildInputs = map swapHook old.nativeBuildInputs;
                    });
                }
              )
            ];
          }
        );

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
