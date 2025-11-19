{ config, pkgs, ... }:
let
  colors = config.lib.stylix.colors;
in
{
  home.packages = with pkgs; [ rofi ];

  xdg.configFile."rofi/theme.rasi".text = ''
    * {
        bg-col: #${colors.base00};
        bg-col-light: #${colors.base01};
        border-col: #${colors.base04};
        selected-col: #${colors.base02};
        green: #${colors.base0B};
        fg-col: #${colors.base05};
        fg-col2: #${colors.base06};
        grey: #${colors.base03};
        highlight: @green;
    }
  '';
  xdg.configFile."rofi/config.rasi".source = ./config.rasi;

  xdg.configFile."rofi/powermenu-theme.rasi".source = ./powermenu-theme.rasi;
}