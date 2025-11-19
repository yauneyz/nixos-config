{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    nerd-fonts.caskaydia-cove
    nerd-fonts.symbols-only
    twemoji-color-font
    noto-fonts-color-emoji
    fantasque-sans-mono
    maple-mono-custom
  ];

  # GTK theming is now handled by Stylix (modules/core/stylix.nix)
}
