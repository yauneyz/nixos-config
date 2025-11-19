{ pkgs, config, lib, ... }:
let
  colors = config.lib.stylix.colors;
in
{
  programs.swaylock = {
    enable = true;

    package = pkgs.swaylock-effects;

    settings = lib.mkForce {
      clock = true;
      daemonize = true;
      # timestr="%H:%M";
      datestr = "";
      screenshots = true;
      ignore-empty-password = true;

      indicator = true;
      indicator-radius = 111;
      indicator-thickness = 9;

      effect-blur = "7x5";
      effect-vignette = "0.75:0.75";
      effect-pixelate = 5;

      font = config.stylix.fonts.monospace.name;

      text-wrong-color = "${colors.base05}FF";
      text-ver-color = "${colors.base05}FF";
      text-clear-color = "${colors.base05}FF";
      key-hl-color = "${colors.base0A}FF";
      bs-hl-color = "${colors.base08}FF";
      ring-clear-color = "${colors.base09}FF";
      ring-wrong-color = "${colors.base08}FF";
      ring-ver-color = "${colors.base0B}FF";
      ring-color = "${colors.base0C}FF";
      line-clear-color = "FFFFFF00";
      line-ver-color = "FFFFFF00";
      line-wrong-color = "FFFFFF00";
      separator-color = "FFFFFF00";
      line-color = "FFFFFF00";
      text-color = "${colors.base05}FF";
      inside-color = "${colors.base02}DD";
      inside-ver-color = "${colors.base02}DD";
      inside-clear-color = "${colors.base02}DD";
      inside-wrong-color = "${colors.base02}DD";
      layout-bg-color = "FFFFFF00";
      layout-text-color = "${colors.base05}FF";
    };
  };
}
