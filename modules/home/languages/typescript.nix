{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs_22

    nodePackages.typescript
    nodePackages.typescript-language-server
    vscode-langservers-extracted

    nodePackages.prettier
    nodePackages.eslint
    nodePackages.mocha

    nodePackages.nodemon
    nodePackages.webpack-cli

    nodePackages.npm-check-updates
    nodePackages.pnpm
    nodePackages.jshint

    ripgrep
    zprint

    nodePackages.yarn

    # ✅ This is the Nix package that corresponds to npm: @github/copilot-language-server
    copilot-language-server
  ];
}
