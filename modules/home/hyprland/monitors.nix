{ config, pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    settings = {
      config.cursor.no_hardware_cursors = true;

      # Set to 120Hz for smoother experience
      monitor = [
        {
          output = "eDP-1";
          mode = "3072x1920@120";
          position = "0x0";
          scale = 2;
        }
      ];
    };

    # nwg-displays 0.55+ writes these Lua files alongside its legacy .conf
    # output. Load them last so an interactively selected layout overrides the
    # declarative fallback above, while still allowing either file to be absent.
    extraConfig = ''
      local hm_xdg_config_home = os.getenv("XDG_CONFIG_HOME") or "${config.xdg.configHome}"
      local function load_nwg_displays_file(name)
        local path = hm_xdg_config_home .. "/hypr/" .. name .. ".lua"
        local file = io.open(path, "r")
        if file then
          file:close()
          dofile(path)
        end
      end

      load_nwg_displays_file("monitors")
      load_nwg_displays_file("workspaces")
    '';
  };

  home.packages = with pkgs; [ nwg-displays ];
}
