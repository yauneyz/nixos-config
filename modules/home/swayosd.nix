{ lib, pkgs, ... }:
let
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

  wayland.windowManager.hyprland = {
    settings = {
      on = [
        {
          _args = [
            "hyprland.start"
            (lua ''
              function()
                hl.exec_cmd("swayosd-server")
              end
            '')
          ];
        }
      ];

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
        padding: 0px 10px;
        border-radius: 25px;
        border: 10px;
        background: alpha(#282828, 0.99);
    }

    #container {
        margin: 15px;
    }

    image, label {
        color: #FBF1C7;
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
        background: alpha(#DDDDDD, 0.2);
    }
    progress {
        min-height: inherit;
        border-radius: inherit;
        border: none;
        background: #FBF1C7;
    }
  '';
}
