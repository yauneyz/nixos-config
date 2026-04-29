{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (wrapRetroArch {
      cores = [
        libretro."mame2003-plus"
      ];
    })
  ];
}
