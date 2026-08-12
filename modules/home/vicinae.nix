{ lib, ... }:
{
  programs.vicinae = {
    enable = true;

    systemd = {
      enable = true;
      autoStart = true;
    };

    settings = {
      font = {
        normal = {
          family = "Maple Mono";
          size = 13;
        };
      };

      launcher_window = {
        layer_shell.enabled = true;

        client_side_decorations = {
          enabled = true;
          rounding = 14;
          border_width = 1;
          shadow_size = 12;
        };
      };

      favicon_service = "twenty";
      pop_to_root_on_close = true;
      search_files_in_root = false;

      favorites = [ "clipboard:history" ];
      fallbacks = [ ];
      providers.files = {
        preferences = {
          autoIndexing = false;
          indexingPaths = [ ];
          excludedIndexingPaths = [ ];
        };
      };
    };
  };

  systemd.user.services.vicinae.Service = {
    Environment = [
      "VICINAE_INPUT_SERVER_BIN=/run/wrappers/bin/vicinae-input-server"
    ];
    KillMode = lib.mkForce "control-group";
  };
}
