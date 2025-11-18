{ pkgs, ... }:
{
  # Nerd fonts for emacs
  fonts.packages = with pkgs; [
    fira-code
    (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" ]; })
  ];
}
