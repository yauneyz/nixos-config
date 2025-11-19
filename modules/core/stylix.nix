{ pkgs, lib, config, ... }:
let
  # Easy toggle between color modes
  # Set to true to derive colors from wallpaper, false to use Gruvbox
  useWallpaperColors = false;

  # Wallpaper path (always required)
  wallpaperPath = ../../wallpapers/otherWallpaper/zac/anime-style-mountains-landscape.jpg;
in
{
  stylix = {
    enable = true;
    autoEnable = true;  # Auto-theme installed applications

    # Wallpaper (required)
    image = wallpaperPath;

    base16Scheme = lib.mkIf (!useWallpaperColors)
      #"${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
      "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";

    # Polarity (matters for wallpaper-derived colors)
    polarity = "dark";

    # Font configuration
    fonts = {
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      monospace = {
        package = pkgs.maple-mono-custom;
        name = "Maple Mono";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };

      sizes = {
        applications = 12;
        terminal = 16;
        desktop = 12;
        popups = 12;
      };
    };

    # Cursor theme
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };

    # Opacity settings
    opacity = {
      terminal = 0.66;
      applications = 1.0;
      popups = 1.0;
      desktop = 1.0;
    };
  };
}
