{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      # Interactive tooling
      python3Packages.ipython

      # Emacs uses Pyright for types/navigation and the native Ruff server.
      pyright

      # Alternative Python LSP and its plugins (for other editors)
      python3Packages.python-lsp-server
      python3Packages.pylsp-mypy
      python3Packages.python-lsp-black
      python3Packages.python-lsp-ruff

      # Formatters, linters, and diagnostics
      python3Packages.black
      python3Packages.mypy
      python3Packages.debugpy
      python3Packages.flake8
      python3Packages.autopep8
      ruff

      # Project/tooling helpers
      poetry
      python3Packages.pipx
      uv
    ];
}
