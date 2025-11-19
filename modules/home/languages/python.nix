{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Python interpreter
    python3

    # Python packages
    python312Packages.ipython
    python312Packages.pip
    python312Packages.virtualenv
    python312Packages.setuptools

    # Language Server Protocol
    python312Packages.python-lsp-server
    python312Packages.pylsp-mypy # Type checking plugin for LSP
    python312Packages.python-lsp-black # Black formatter plugin for LSP
    python312Packages.python-lsp-ruff # Ruff linter plugin for LSP

    # Formatters
    python312Packages.black
    ruff # Fast Python linter and formatter

    # Type checking
    python312Packages.mypy

    # Testing
    python312Packages.pytest
    python312Packages.pytest-cov
    python312Packages.pytest-xdist

    # Debugger
    python312Packages.debugpy

    # Code quality and analysis
    python312Packages.flake8
    python312Packages.pylint
    python312Packages.autopep8

    # Utilities
    poetry # Modern dependency management
    python312Packages.pipx # Install Python applications in isolated environments
    uv # Astral's fast Python package installer/runner
  ];

  # Set up Python environment
  home.sessionVariables = {
    PYTHONPATH = "$HOME/.local/lib/python3.12/site-packages";
  };
}
