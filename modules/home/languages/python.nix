{
  pkgs,
  host,
  inputs,
  ...
}:
let
  cudaPkgs =
    if host == "desktop" then
      import inputs.nixpkgs {
        inherit (pkgs.stdenv.hostPlatform) system;
        config = {
          allowUnfree = true;
          allowBroken = true;
          cudaSupport = true;
        };
        overlays = [
          (final: prev: {
            xorg = prev.xorg // {
              xrdb = prev.xrdb;
              lndir = prev.lndir;
            };
          })
          (
            final: prev:
            (import ../../../pkgs {
              inherit inputs;
              pkgs = final;
              inherit prev;
              inherit (prev) system;
            })
          )
        ];
      }
    else
      null;
in
{
  home.packages =
    with pkgs;
    [
      # Interactive tooling
      python312Packages.ipython

      # Language Server Protocol + helpers
      python312Packages.python-lsp-server
      python312Packages.pylsp-mypy
      python312Packages.python-lsp-black
      python312Packages.python-lsp-ruff

      # Formatters, linters, and diagnostics
      python312Packages.black
      python312Packages.mypy
      python312Packages.debugpy
      python312Packages.flake8
      python312Packages.pylint
      python312Packages.autopep8
      ruff

      # Project/tooling helpers
      poetry
      python312Packages.pipx
      uv
    ]
    ++ (
      if host == "desktop" then
        [
          # GLM/vLLM runtime dependencies.
          python312Packages.transformers
          python312Packages.huggingface-hub

          # CUDA-backed OpenAI-compatible server for local models.
          cudaPkgs.python312Packages.vllm
        ]
      else
        [ ]
    );
}
