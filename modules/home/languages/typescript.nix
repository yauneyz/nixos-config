{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Node.js runtime and npm
    nodejs_22

    # TypeScript compiler
    nodePackages.typescript

    # Language Server Protocol
    nodePackages.typescript-language-server
    vscode-langservers-extracted # Provides HTML/CSS/JSON/ESLint language servers

    # Formatters
    nodePackages.prettier

    # Linters
    nodePackages.eslint

    # Testing frameworks
    nodePackages.mocha
    # Note: Install jest and other test runners per-project via npm

    # Debugging and development
    nodePackages.nodemon # Auto-restart on file changes
    # Note: Install ts-node per-project via npm

    # Build tools
    nodePackages.webpack-cli
    # Note: Install webpack, vite, and other build tools per-project via npm

    # Package management utilities
    nodePackages.npm-check-updates # Check for outdated packages
    nodePackages.pnpm # Alternative package manager

    # Code quality
    nodePackages.jshint
    ripgrep

    # Formatting utilities
    zprint

    # Package managers
    nodePackages.yarn # Alternative package manager
    # Note: npm comes with nodejs
  ];

  # Set up npm global directory to avoid permission issues
  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };

  home.sessionPath = [
    "$HOME/.npm-global/bin"
  ];
}
