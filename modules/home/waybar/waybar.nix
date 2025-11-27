{ lib, ... }:
{
  programs.waybar = {
    enable = true;
    style = lib.mkAfter ''
      #waybar {
        background-color: transparent;
        border: none;
      }

      #workspaces button,
      #workspaces button label {
        color: #ffffff;
      }
    '';
  };
}
