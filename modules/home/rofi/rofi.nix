{ config, pkgs, ... }:
let
  colors = config.lib.stylix.colors;
in
{
  home.packages = with pkgs; [ rofi ];

  xdg.configFile."rofi/theme.rasi".text = ''
    * {
        bg-col: #${colors.base00}ed;
        bg-col-light: #${colors.base01}f5;
        border-col: #${colors.base0D};
        selected-col: #${colors.base02}f5;
        green: #${colors.base0B};
        accent: #${colors.base0C};
        urgent: #${colors.base08};
        fg-col: #${colors.base05};
        fg-col2: #${colors.base06};
        grey: #${colors.base03};
        highlight: @green;
    }
  '';
  xdg.configFile."rofi/config.rasi".source = ./config.rasi;

  xdg.configFile."rofi/powermenu-theme.rasi".source = ./powermenu-theme.rasi;
}
