{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.zac.grubTheme;

  # Gorgeous-GRUB is a gallery rather than a theme repository. Keep each
  # upstream pinned here and expose a consistent collection.variant selector.
  hollowSource = pkgs.fetchFromGitHub {
    owner = "sergoncano";
    repo = "hollow-knight-grub-theme";
    rev = "9515f805f72dc214e3da59967f0b678d9910adf1";
    hash = "sha256-0hn3MFC+OtfwtA//pwjnWz7Oz0Cos3YzbgUlxKszhyA=";
  };

  sekiroNormalSource = pkgs.fetchFromGitHub {
    owner = "AbijithBalaji";
    repo = "sekiro_grub_theme";
    rev = "1b1e3840e9c378f4400bed2a8940f4ded364ba3f";
    hash = "sha256-uXwDjb0+ViQvdesG5gefC5zFAiFs/FfDfeI5t7vP+Qc=";
  };

  # Sekiro Shadow is one directory in this collection. Fetching the complete
  # repository also makes its other theme assets available for future entries.
  grubThemesSource = pkgs.fetchFromGitHub {
    owner = "MrVivekRajan";
    repo = "Grub-Themes";
    rev = "cefbbf6a13b9bb3405c66219a5b4ead5d4f31fca";
    hash = "sha256-Z/FmySvFZW11Qv6mfMGZHbHLc8hmz2hhDQFaxb+1OHU=";
  };

  mkHollowVariant =
    name: wallpaper:
    pkgs.runCommand "hollow-grub-${name}" { } ''
      mkdir -p "$out"
      cp -r ${hollowSource}/hollow-grub/. "$out/"
      chmod -R u+w "$out"
      cp ${hollowSource}/wallpapers/${wallpaper}.png "$out/wallpaper.png"
    '';

  # Every installable theme in MrVivekRajan/Grub-Themes. Keeping the path map
  # explicit makes the option names stable even when upstream reorganizes.
  communityThemePaths = {
    aesthetic = "Aesthetic";
    anime = "Anime";
    cartoon-girl = "CartoonGirl";
    doraemon = "Doraemon";
    gradient-color = "GradientColor";
    neon-purple = "NeonPurple";
    sekiro-shadow = "SekiroShadow";
    windows-main = "Windows-Main/Windows";

    "minimal.arch" = "Minimal/Arch";
    "minimal.centos" = "Minimal/CentOS";
    "minimal.chrome-os" = "Minimal/ChromeOS";
    "minimal.debian" = "Minimal/Debian";
    "minimal.elementary" = "Minimal/Elementary";
    "minimal.fedora" = "Minimal/Fedora";
    "minimal.kali" = "Minimal/Kali";
    "minimal.kubuntu" = "Minimal/Kubuntu";
    "minimal.lubuntu" = "Minimal/Lubuntu";
    "minimal.macos" = "Minimal/MacOS";
    "minimal.manjaro" = "Minimal/Manjaro";
    "minimal.mint" = "Minimal/Mint";
    "minimal.nixos" = "Minimal/NIXOS";
    "minimal.opensuse" = "Minimal/OpenSuse";
    "minimal.pop-os" = "Minimal/PopOS";
    "minimal.solus" = "Minimal/Solus";
    "minimal.ubuntu" = "Minimal/Ubuntu";
    "minimal.void" = "Minimal/Void";
    "minimal.windows" = "Minimal/Windows";
    "minimal.zorin" = "Minimal/Zorin";
  };

  communityThemes = lib.mapAttrs' (
    name: path: lib.nameValuePair "grub-themes.${name}" "${grubThemesSource}/${path}"
  ) communityThemePaths;

  gorgeousThemes = {
    "cyber-xero" = ./grub-themes/CyberXero;

    "sekiro.normal" = "${sekiroNormalSource}/Sekiro";
    "sekiro.shadow" = "${grubThemesSource}/SekiroShadow";

    "hollow-grub.default" = "${hollowSource}/hollow-grub";
    "hollow-grub.godmaster" = mkHollowVariant "godmaster" "Godmaster";
    "hollow-grub.grimm-troupe" = mkHollowVariant "grimm-troupe" "Grimm_Troupe";
    "hollow-grub.hidden-dreams" = mkHollowVariant "hidden-dreams" "Hidden_Dreams";
    "hollow-grub.infected" = mkHollowVariant "infected" "Infected";
    "hollow-grub.lifeblood" = mkHollowVariant "lifeblood" "Lifeblood";
    "hollow-grub.steel-soul" = mkHollowVariant "steel-soul" "Steel_Soul";
    "hollow-grub.eternal-ordeal" = mkHollowVariant "eternal-ordeal" "The_Eternal_Ordeal";
    "hollow-grub.void" = mkHollowVariant "void" "Void";
    "hollow-grub.voidheart" = mkHollowVariant "voidheart" "Voidheart";
  };

  themes = gorgeousThemes // communityThemes;

  themeNames = builtins.attrNames themes;
in
{
  options.zac.grubTheme = lib.mkOption {
    type = lib.types.nullOr (lib.types.enum themeNames);
    default = null;
    example = "sekiro.shadow";
    description = ''
      GRUB theme to use. Theme sets use collection.variant names. Available
      selections: ${lib.concatStringsSep ", " themeNames}.
    '';
  };

  config = lib.mkIf (cfg != null) {
    assertions = [
      {
        assertion = config.boot.loader.grub.enable;
        message = "zac.grubTheme requires boot.loader.grub.enable = true";
      }
    ];

    boot.loader.grub.theme = themes.${cfg};
  };
}
