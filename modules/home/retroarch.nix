{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (wrapRetroArch {
      cores = [
        libretro."mame2003-plus"
        libretro.mgba # Game Boy, Game Boy Color, and Game Boy Advance
      ];
    })
  ];
}
