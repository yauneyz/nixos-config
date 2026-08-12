{
  pkgs,
  lib,
  config,
  ...
}:
let
  wallpaperPath = ../../wallpapers/sakura-shrine-night.png;

  # Ink-black surfaces and warm sakura accents tuned for the shrine wallpaper
  # pair.  Neutral foregrounds keep code calm and readable over translucent
  # terminals; the muted sage and amber are reserved for semantic status.
  sakuraNoir = {
    scheme = "Sakura Noir";
    author = "Zac Yauney";
    base00 = "070607";
    base01 = "110a0d";
    base02 = "241218";
    base03 = "6f4c54";
    base04 = "b79097";
    base05 = "e7d9d8";
    base06 = "f1e6e3";
    base07 = "fbf5f0";
    base08 = "f06466";
    base09 = "e4775b";
    base0A = "e7b269";
    base0B = "a9c78e";
    base0C = "f0a7b2";
    base0D = "dc3b59";
    base0E = "e879a0";
    base0F = "ad727d";
  };

in
{
  stylix = {
    enable = true;
    enableReleaseChecks = false;
    autoEnable = true; # Auto-theme installed applications

    # Disable GRUB theming (using custom theme instead)
    targets.grub.enable = false;

    # Disable kmscon theming: stylix's kmscon module still sets the removed
    # services.kmscon.{extraConfig,fonts} options, which newer nixpkgs rejects.
    # We don't use kmscon, so just turn the target off.
    targets.kmscon.enable = false;

    # SDDM is our display manager. The ReGreet target still writes the renamed
    # programs.regreet options on nixpkgs 26.11 even when ReGreet is disabled.
    targets.regreet.enable = false;

    # Wallpaper (required)
    image = wallpaperPath;
    base16Scheme = sakuraNoir;

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
      name = "Bibata-Modern-Classic";
      size = 24;
    };

    # Opacity settings
    opacity = {
      terminal = 0.86;
      applications = 0.98;
      popups = 0.96;
      desktop = 0.94;
    };
  };
}
