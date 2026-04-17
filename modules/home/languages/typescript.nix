{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs_22
    bun

    typescript
    typescript-language-server
    vscode-langservers-extracted

    prettier
    eslint
    mocha

    nodemon
    webpack-cli

    npm-check-updates
    pnpm
    jshint

    ripgrep
    zprint

    yarn

    # ✅ This is the Nix package that corresponds to npm: @github/copilot-language-server
    copilot-language-server
  ];
}
