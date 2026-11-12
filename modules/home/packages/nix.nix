{ inputs, pkgs, ... }:
{
  imports = [
    inputs.nix-index-database.homeModules.nix-index
  ];

  programs = {
    nix-index = {
      enable = true;
      symlinkToCacheHome = false;
      enableZshIntegration = false;
    };

    nix-index-database.comma.enable = true;
  };

  home.packages = with pkgs; [
    nvd                               # Nix/NixOS package version diff tool
    nix-du                            # Tool to determine which gc-roots take space in your nix store
    nix-btm                           # Bottom-like system monitor for nix
    nix-web                           # Web interface for the Nix store
    nix-tree                          # Interactively browse a Nix store paths dependencies
    nix-melt                          # Ranger-like flake.lock viewer
    nix-output-monitor                # Processes output of Nix commands to show helpful and pretty information
    nixtract                          # A CLI tool to extract the graph of derivations from a Nix flake
    statix                            # Nix linter (anti-patterns), `statix fix` autofixes
    deadnix                           # Find unused bindings / lambda args in Nix
    nurl                              # Generate fetcher calls with hashes: nurl <url> [rev]
    nix-init                          # Scaffold a derivation from a URL
    sops                              # edit encrypted secrets: sops secrets/secrets.yaml
    age                               # age-keygen etc. for sops keys
  ];

  # Lint the whole config: anti-patterns + dead code (read-only).
  programs.zsh.shellAliases = {
    nixlint = "statix check ~/nixos-config; deadnix --no-lambda-pattern-names ~/nixos-config/modules ~/nixos-config/hosts ~/nixos-config/pkgs ~/nixos-config/flake.nix";
  };
}
