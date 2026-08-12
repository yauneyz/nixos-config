{ config, lib, pkgs, ... }:
let
  colors = config.lib.stylix.colors.withHashtag;
  lua = lib.generators.mkLuaInline;
  bind = keys: command: options: {
    _args = [
      keys
      (lua "hl.dsp.exec_cmd(${builtins.toJSON command})")
      options
    ];
  };
in
{
  home.packages = with pkgs; [ swayosd ];

  wayland.windowManager.hyprland = lib.mkIf (config.zac.desktop.shell.backend == "legacy") {
    settings = {
      bind = [
        (bind "XF86AudioMute" "swayosd-client --output-volume mute-toggle" { })

        # Binds active on the lock screen.
        (bind "XF86MonBrightnessUp" "swayosd-client --brightness raise 5%+" { locked = true; })
        (bind "XF86MonBrightnessDown" "swayosd-client --brightness lower 5%-" { locked = true; })
        (bind "ALT + XF86MonBrightnessUp" "brightnessctl set 100%" { locked = true; })
        (bind "ALT + XF86MonBrightnessDown" "brightnessctl set 0%" { locked = true; })

        (bind "XF86AudioRaiseVolume" "swayosd-client --output-volume +2 --max-volume=100" {
          locked = true;
          repeating = true;
        })
        (bind "XF86AudioLowerVolume" "swayosd-client --output-volume -2" {
          locked = true;
          repeating = true;
        })
        (bind "ALT + f11" "swayosd-client --output-volume +2 --max-volume=100" {
          locked = true;
          repeating = true;
        })
        (bind "ALT + f12" "swayosd-client --output-volume -2" {
          locked = true;
          repeating = true;
        })

        (bind "CAPS + Caps_Lock" "swayosd-client --caps-lock" { release = true; })
        (bind "Scroll_Lock" "swayosd-client --scroll-lock" { release = true; })
        (bind "Num_Lock" "swayosd-client --num-lock" { release = true; })
      ];
    };
  };

  xdg.configFile."swayosd/style.css".text = ''
    window {
        padding: 0 10px;
        border-radius: 16px;
        border: 1px solid alpha(${colors.base03}, 0.7);
        background: alpha(${colors.base00}, 0.94);
        box-shadow: 0 6px 20px alpha(#000000, 0.4);
    }

    #container {
        margin: 15px;
    }

    image, label {
        color: ${colors.base05};
    }

    progressbar:disabled,
    image:disabled {
        opacity: 0.95;
    }

    progressbar {
        min-height: 6px;
        border-radius: 999px;
        background: transparent;
        border: none;
    }
    trough {
        min-height: inherit;
        border-radius: inherit;
        border: none;
        background: alpha(${colors.base02}, 0.9);
    }
    progress {
        min-height: inherit;
        border-radius: inherit;
        border: none;
        background: ${colors.base0D};
    }
  '';
}
