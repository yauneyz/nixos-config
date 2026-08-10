{ lib, ... }:
let
  curve = name: points: {
    _args = [
      name
      {
        type = "bezier";
        inherit points;
      }
    ];
  };
in
{
  wayland.windowManager.hyprland = {
    settings = {
      config = {
        cursor = {
          enable_hyprcursor = true;
          warp_on_change_workspace = false;
          no_warps = false;
          persistent_warps = false;
          # Cursor size workaround for scaling
          default_monitor = "eDP-1";
        };

        input = {
          kb_layout = "us";
          kb_options = "ctrl:nocaps";
          numlock_by_default = true;
          repeat_delay = 300;
          follow_mouse = 1;
          float_switch_override_focus = 0;
          mouse_refocus = 1;
          sensitivity = 0;
          touchpad.natural_scroll = true;
        };

        general = {
          layout = "dwindle";
          gaps_in = 6;
          gaps_out = 12;
          border_size = 2;
          # Border colors are set by Stylix.
        };

        misc = {
          disable_hyprland_logo = true;
          always_follow_on_dnd = true;
          layers_hog_keyboard_focus = true;
          animate_manual_resizes = false;
          enable_swallow = true;
          focus_on_activate = true;
          on_focus_under_fullscreen = 2;
          middle_click_paste = false;
        };

        dwindle = {
          force_split = 2;
          special_scale_factor = 1.0;
          split_width_multiplier = 1.0;
          use_active_for_splits = true;
          preserve_split = true;
        };

        master = {
          new_status = "master";
          special_scale_factor = 1;
        };

        decoration = {
          rounding = 0;

          blur = {
            enabled = true;
            size = 3;
            passes = 2;
            brightness = 1;
            contrast = 1.4;
            ignore_opacity = true;
            noise = 0;
            new_optimizations = true;
            xray = true;
          };

          shadow = {
            enabled = true;
            offset = "0 2";
            range = 20;
            render_power = 3;
            # Shadow color is set by Stylix.
          };
        };

        animations.enabled = true;

        xwayland = {
          force_zero_scaling = true;
          # Helps avoid blur if scaling ever changes.
          use_nearest_neighbor = true;
        };
      };

      curve = [
        (curve "fluent_decel" [
          [
            0
            0.2
          ]
          [
            0.4
            1
          ]
        ])
        (curve "easeOutCirc" [
          [
            0
            0.55
          ]
          [
            0.45
            1
          ]
        ])
        (curve "easeOutCubic" [
          [
            0.33
            1
          ]
          [
            0.68
            1
          ]
        ])
        (curve "fade_curve" [
          [
            0
            0.55
          ]
          [
            0.45
            1
          ]
        ])
      ];

      animation = [
        {
          leaf = "windowsIn";
          enabled = false;
          speed = 4;
          bezier = "easeOutCubic";
          style = "popin 20%";
        }
        {
          leaf = "windowsOut";
          enabled = false;
          speed = 4;
          bezier = "fluent_decel";
          style = "popin 80%";
        }
        {
          leaf = "windowsMove";
          enabled = true;
          speed = 2;
          bezier = "fluent_decel";
          style = "slide";
        }
        {
          leaf = "fadeIn";
          enabled = true;
          speed = 3;
          bezier = "fade_curve";
        }
        {
          leaf = "fadeOut";
          enabled = true;
          speed = 3;
          bezier = "fade_curve";
        }
        {
          leaf = "fadeSwitch";
          enabled = false;
          speed = 1;
          bezier = "easeOutCirc";
        }
        {
          leaf = "fadeShadow";
          enabled = true;
          speed = 10;
          bezier = "easeOutCirc";
        }
        {
          leaf = "fadeDim";
          enabled = true;
          speed = 4;
          bezier = "fluent_decel";
        }
        {
          leaf = "workspaces";
          enabled = true;
          speed = 4;
          bezier = "easeOutCubic";
          style = "fade";
        }
      ];

      device = {
        name = "logitech-mx-ergo-multi-device-trackball-";
        sensitivity = 1.0;
        accel_profile = "adaptive";
      };
    };
  };
}
