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
}
