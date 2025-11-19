{ config, ... }:
let
  colors = config.lib.stylix.colors.withHashtag;
in
{
  programs.cava = {
    enable = true;

    settings = {
      color = {
        gradient = 1;
        gradient_count = 8;

        gradient_color_1 = "'${colors.base08}'"; # red
        gradient_color_2 = "'${colors.base09}'"; # orange
        gradient_color_3 = "'${colors.base0A}'"; # yellow
        gradient_color_4 = "'${colors.base0B}'"; # bright green
        gradient_color_5 = "'${colors.base0B}'"; # green
        gradient_color_6 = "'${colors.base0D}'"; # blue
        gradient_color_7 = "'${colors.base0E}'"; # purple
        gradient_color_8 = "'${colors.base05}'"; # light foreground
      };
    };
  };
}
