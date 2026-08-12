{ config, ... }:
let
  colors = config.lib.stylix.colors.withHashtag;
  font = config.stylix.fonts.monospace.name;
  fontSize = toString config.stylix.fonts.sizes.applications;
in
{
  programs.waybar.style = ''
    * {
      border: none;
      border-radius: 0;
      min-height: 0;
      font-family: "${font}";
      font-size: ${fontSize}px;
      font-weight: 700;
    }

    window#waybar {
      background: transparent;
      color: ${colors.base05};
    }

    #navigation,
    #system,
    #connectivity,
    #session,
    #workspaces {
      background: alpha(${colors.base00}, 0.88);
      border: 1px solid alpha(${colors.base03}, 0.55);
      border-radius: 12px;
      box-shadow: 0 4px 14px alpha(#000000, 0.38);
      padding: 0 5px;
    }

    #custom-launcher,
    #tray,
    #cpu,
    #memory,
    #disk,
    #pulseaudio,
    #network,
    #battery,
    #language,
    #custom-notification,
    #clock,
    #custom-power-menu {
      padding: 0 7px;
      margin: 3px 0;
      color: ${colors.base05};
    }

    #custom-launcher {
      color: ${colors.base0C};
      font-size: 16px;
      padding-left: 8px;
    }

    #tray {
      padding-right: 8px;
    }

    #workspaces {
      padding: 2px 4px;
    }

    #workspaces button {
      min-width: 25px;
      min-height: 26px;
      margin: 1px 2px;
      padding: 0 6px;
      border-radius: 8px;
      color: ${colors.base04};
      background: transparent;
      box-shadow: none;
      text-shadow: none;
      transition: background-color 120ms ease, color 120ms ease;
    }

    #workspaces button:hover {
      color: ${colors.base06};
      background: alpha(${colors.base02}, 0.92);
    }

    #workspaces button.active {
      color: ${colors.base00};
      background: ${colors.base0D};
    }

    #workspaces button.urgent {
      color: ${colors.base00};
      background: ${colors.base08};
    }

    #clock {
      color: ${colors.base06};
      padding-left: 9px;
      padding-right: 9px;
    }

    #custom-notification {
      color: ${colors.base0E};
    }

    #custom-power-menu {
      color: ${colors.base08};
      padding-right: 9px;
    }

    #battery.warning:not(.charging) {
      color: ${colors.base09};
    }

    #battery.critical:not(.charging) {
      color: ${colors.base08};
    }

    tooltip {
      background: alpha(${colors.base00}, 0.96);
      border: 1px solid ${colors.base03};
      border-radius: 10px;
      color: ${colors.base05};
    }

    tooltip label {
      color: ${colors.base05};
      padding: 7px;
    }
  '';
}
