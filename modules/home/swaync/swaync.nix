{ pkgs, config, ... }:
let
  colors = config.lib.stylix.colors.withHashtag;

  # Read the original CSS and inject Stylix color variables
  styleCss = builtins.readFile ./style.css;

  # Generate CSS with Stylix colors in :root variables
  styledCss = ''
    :root {
        --bg-primary: ${colors.base00};
        --bg-secondary: ${colors.base01};
        --bg-button: ${colors.base02};
        --bg-button-hover: ${colors.base03};
        --text-primary: ${colors.base05};
        --text-disabled: ${colors.base03};
        --border-color: ${colors.base04};
        --priority-low: ${colors.base05};
        --priority-normal: ${colors.base0D};
        --priority-critical: ${colors.base08};
        --transition-standard: 0.15s ease-in-out;
    }

    ${
      # Remove the :root section from the original CSS (lines 1-13)
      let
        lines = pkgs.lib.splitString "\n" styleCss;
        # Skip first 13 lines (the :root section)
        remainingLines = pkgs.lib.drop 13 lines;
      in
        pkgs.lib.concatStringsSep "\n" remainingLines
    }
  '';
in
{
  home.packages = with pkgs; [ swaynotificationcenter ];

  xdg.configFile."swaync/style.css".text = styledCss;
  xdg.configFile."swaync/config.json".source = ./config.json;
}
