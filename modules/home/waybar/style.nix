{ config, ... }:
let
  colors = config.lib.stylix.colors.withHashtag;
  custom = {
    font = config.stylix.fonts.monospace.name;
    font_size = "${toString config.stylix.fonts.sizes.applications}px";
    font_weight = "bold";
    text_color = colors.base05;
    background_0 = colors.base00;
    background_1 = colors.base01;
    border_color = colors.base04;
    red = colors.base08;
    green = colors.base0B;
    yellow = colors.base0A;
    blue = colors.base0D;
    magenta = colors.base0E;
    cyan = colors.base0C;
    orange = colors.base09;
    orange_bright = colors.base09;
    opacity = "1";
    indicator_height = "2px";
  };
in
{
  programs.waybar.style = with custom; ''
    * {
      border: none;
      border-radius: 0px;
      padding: 0;
      margin: 0;
      font-family: ${font};
      font-weight: ${font_weight};
      opacity: ${opacity};
      font-size: ${font_size};
      min-height: 0;
      color: @theme_text_color;
    }

    window#waybar {
      background: shade(@theme_bg_color, 0.85);
      border-top: 1px solid @unfocused_borders;
      color: @theme_text_color;
      box-shadow: 0 -3px 18px alpha(@theme_text_color, 0.08);
    }

    box.modules-left,
    box.modules-center,
    box.modules-right {
      background: alpha(@theme_base_color, 0.55);
      border: 1px solid alpha(@unfocused_borders, 0.7);
      border-radius: 16px;
      padding: 4px 10px;
      margin: 6px 12px;
      box-shadow: 0 3px 12px alpha(@theme_text_color, 0.12);
    }

    tooltip {
      background: shade(@theme_base_color, 0.85);
      border: 1px solid alpha(@unfocused_borders, 0.75);
    }
    tooltip label {
      margin: 5px;
      color: @theme_text_color;
    }

    #workspaces {
      padding-left: 10px;
      padding-right: 10px;
    }
    #workspaces button {
      /* GTK CSS subset lacks text-align/display, rely on native centering */
      color: @theme_text_color;
      background: shade(@theme_base_color, 0.65);
      padding: 4px 14px;
      margin: 0 6px;
      border-radius: 999px;
      min-width: 34px;
      border: 1px solid alpha(@unfocused_borders, 0.8);
      box-shadow: inset 0 0 0 1px alpha(@theme_text_color, 0.02);
      transition: background 0.2s ease, color 0.2s ease, border 0.2s ease, box-shadow 0.2s ease;
    }
    #workspaces button.empty {
      color: alpha(@theme_text_color, 0.75);
      background: shade(@theme_base_color, 0.7);
    }
    #workspaces button.active {
      background: alpha(@theme_selected_bg_color, 0.92);
      color: @theme_selected_fg_color;
      border-color: @theme_selected_bg_color;
      box-shadow: 0 0 12px alpha(@theme_selected_bg_color, 0.45);
    }
    #workspaces button:hover {
      background: shade(@theme_base_color, 0.8);
      color: @theme_text_color;
    }
    #workspaces button.urgent {
      background: alpha(${red}, 0.2);
      border-color: ${red};
      color: ${red};
    }

    #clock {
      color: @theme_text_color;
      background: shade(@theme_base_color, 0.7);
      padding: 2px 16px;
      border-radius: 999px;
      border: 1px solid alpha(@unfocused_borders, 0.8);
      box-shadow: inset 0 0 0 1px alpha(@theme_text_color, 0.03);
    }

    #tray {
      margin-left: 12px;
      color: @theme_text_color;
    }
    #tray menu {
      background: shade(@theme_base_color, 0.85);
      border: 1px solid alpha(@unfocused_borders, 0.7);
      padding: 8px;
    }
    #tray menuitem {
      padding: 1px;
    }

    #pulseaudio, #network, #cpu, #memory, #disk, #battery, #language, #custom-notification, #custom-power-menu {
      padding-left: 5px;
      padding-right: 5px;
      margin-right: 10px;
      color: @theme_text_color;
      background: shade(@theme_base_color, 0.72);
      border-radius: 12px;
      border: 1px solid alpha(@unfocused_borders, 0.75);
      padding-top: 2px;
      padding-bottom: 2px;
    }

    #pulseaudio, #language, #custom-notification {
      margin-left: 15px;
    }

    #custom-power-menu {
      padding-right: 2px;
      margin-right: 5px;
    }

    #custom-launcher {
      font-size: 20px;
      color: @theme_text_color;
      font-weight: bold;
      margin-left: 10px;
      padding-right: 10px;
    }
  '';
}
