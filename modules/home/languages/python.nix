{ pkgs, ... }:
{
  home.packages = with pkgs; [
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
  ];

  # Python packages in virtualenvs need LD_LIBRARY_PATH for C extensions
  # Set in shell environment to avoid boot hangs from sessionVariables
  # Uses nix-ld's managed library collection from modules/core/program.nix
  programs.zsh.envExtra = ''
    # Add nix-ld library path for Python virtualenv C extensions (pytest, etc.)
    # Prepend to path and preserve any existing LD_LIBRARY_PATH
    export LD_LIBRARY_PATH="/run/current-system/sw/share/nix-ld/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  '';
}
