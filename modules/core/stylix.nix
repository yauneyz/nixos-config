{ pkgs, lib, config, ... }:
let
  wallpaperPath = ../../wallpapers/cosmic-nebula-blue.jpg;

  # A low-luminance, cool palette tuned for the cosmic wallpaper pair.  The
  # foreground/background contrast remains high even when terminals are
  # translucent, while cyan, blue, violet, and amber provide distinct accents.
  cosmicNight = {
    scheme = "Cosmic Night";
    author = "Zac Yauney";
    base00 = "09111a";
    base01 = "101b27";
    base02 = "1b2a38";
    base03 = "526579";
    base04 = "91a4b7";
    base05 = "d7e2ec";
    base06 = "e7eef5";
    base07 = "f5f8fb";
    base08 = "ef6f7a";
    base09 = "e9a66b";
    base0A = "e5cc72";
    base0B = "82c99a";
    base0C = "5ccfe6";
    base0D = "6aa9ff";
    base0E = "ad8cff";
    base0F = "d08fb3";
  };

in
{
  stylix = {
    enable = true;
    enableReleaseChecks = false;
    autoEnable = true;  # Auto-theme installed applications

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
    base16Scheme = cosmicNight;

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
      terminal = 0.84;
      applications = 0.98;
      popups = 0.96;
      desktop = 0.94;
    };
  };
}
