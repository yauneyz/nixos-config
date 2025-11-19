{ pkgs, ... }:

{
  # GRUB Theme Configuration
  # This module makes it easy to switch between different GRUB themes
  # Just uncomment the theme you want to use and comment out the others

  # Fetch Hollow Knight theme from GitHub
  boot.loader.grub.theme = let
    hollow-knight-theme = pkgs.fetchFromGitHub {
      owner = "sergoncano";
      repo = "hollow-knight-grub-theme";
      rev = "master";
      sha256 = "sha256-0hn3MFC+OtfwtA//pwjnWz7Oz0Cos3YzbgUlxKszhyA=";
    };
  in "${hollow-knight-theme}/hollow-grub/theme.txt";

  # Cyberpunk (Atomic) theme - Uncomment to use
  # boot.loader.grub.theme = let
  #   cyberpunk-theme = pkgs.fetchFromGitHub {
  #     owner = "lfelipe1501";
  #     repo = "Atomic-GRUB2-Theme";
  #     rev = "master";
  #     sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Will be updated on first build
  #   };
  # in "${cyberpunk-theme}/Atomic/theme.txt";

  # To add more themes from GitHub:
  # 1. Find the theme repository on GitHub
  # 2. Copy the pattern above
  # 3. Update owner, repo, and the path to theme.txt
  # 4. Run `nix-build` to get the correct sha256 hash
  #
  # Example structure:
  # boot.loader.grub.theme = let
  #   your-theme = pkgs.fetchFromGitHub {
  #     owner = "github-username";
  #     repo = "theme-repo-name";
  #     rev = "master"; # or specific commit/tag
  #     sha256 = "sha256-...";
  #   };
  # in "${your-theme}/path/to/theme.txt";
}
