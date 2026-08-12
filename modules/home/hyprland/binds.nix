{ config, lib, ... }:
let
  lua = lib.generators.mkLuaInline;
  mkBindWith = keys: dispatcher: options: {
    _args = [
      keys
      (lua dispatcher)
      options
    ];
  };
  mkBind = keys: dispatcher: {
    _args = [
      keys
      (lua dispatcher)
    ];
  };
  exec = command: "hl.dsp.exec_cmd(${builtins.toJSON command})";

  workspaceKeys = [
    {
      key = "1";
      workspace = 1;
    }
    {
      key = "2";
      workspace = 2;
    }
    {
      key = "3";
      workspace = 3;
    }
    {
      key = "4";
      workspace = 4;
    }
    {
      key = "5";
      workspace = 5;
    }
    {
      key = "6";
      workspace = 6;
    }
    {
      key = "7";
      workspace = 7;
    }
    {
      key = "8";
      workspace = 8;
    }
    {
      key = "9";
      workspace = 9;
    }
    {
      key = "0";
      workspace = 10;
    }
    {
      key = "w";
      workspace = 11;
    }
    {
      key = "y";
      workspace = 12;
    }
    {
      key = "u";
      workspace = 13;
    }
    {
      key = "o";
      workspace = 14;
    }
    {
      key = "p";
      workspace = 15;
    }
  ];

  directions = [
    {
      key = "left";
      direction = "l";
      x = -80;
      y = 0;
    }
    {
      key = "right";
      direction = "r";
      x = 80;
      y = 0;
    }
    {
      key = "up";
      direction = "u";
      x = 0;
      y = -80;
    }
    {
      key = "down";
      direction = "d";
      x = 0;
      y = 80;
    }
    {
      key = "h";
      direction = "l";
      x = -80;
      y = 0;
    }
    {
      key = "j";
      direction = "d";
      x = 0;
      y = 80;
    }
    {
      key = "k";
      direction = "u";
      x = 0;
      y = -80;
    }
    {
      key = "l";
      direction = "r";
      x = 80;
      y = 0;
    }
  ];

  applicationBinds = [
    (mkBind "ALT + T" (exec "ghostty --gtk-single-instance=true"))
    (mkBind "ALT + I" (exec "firefox-devedition"))
    (mkBind "ALT + N" (exec "nautilus"))
    (mkBind "ALT + M" (exec "spotify"))
    (mkBind "ALT + E" (exec "emacs"))
    (mkBind "ALT + SHIFT + E" (exec "restart-emacs-daemon.sh"))
    (mkBind "ALT + D" (exec "rofi -show drun"))
    (mkBind "ALT + SHIFT + V" (exec "vicinae cmd launch clipboard:history"))
    (mkBind "ALT + Z" (exec "toggle-monitor"))
    (mkBind "ALT + B" (exec "bluetoothctl connect 94:DB:56:F7:A5:C7"))
    (mkBind "ALT + SHIFT + B" (exec "overskride"))
    (mkBind "ALT + CTRL + SHIFT + B" (exec "bluetoothctl disconnect 94:DB:56:F7:A5:C7"))
  ];

  windowBinds = [
    (mkBind "ALT + SHIFT + Q" "hl.dsp.window.close()")
    (mkBind "ALT + SHIFT + X" (exec "hyprctl kill"))
    (mkBind "ALT + F" ''hl.dsp.window.fullscreen({ mode = "fullscreen" })'')
    (mkBind "ALT + Space" "hl.dsp.window.float()")
    (mkBind "ALT + V" ''hl.dsp.layout("preselect d")'')
    (mkBind "ALT + minus" ''hl.dsp.workspace.toggle_special("scratchpad")'')
    (mkBind "ALT + SHIFT + minus" ''hl.dsp.window.move({ workspace = "special:scratchpad", follow = true })'')
    (mkBind "ALT + Tab" ''hl.dsp.focus({ workspace = "previous" })'')
    (mkBind "CTRL + ALT + up" ''hl.dsp.focus({ window = "floating" })'')
    (mkBind "CTRL + ALT + down" ''hl.dsp.focus({ window = "tiled" })'')
  ];

  focusBinds = lib.concatMap (entry: [
    (mkBind "ALT + ${entry.key}" "hl.dsp.focus({ direction = \"${entry.direction}\" })")
    (mkBind "ALT + ${entry.key}" ''hl.dsp.window.alter_zorder({ mode = "top" })'')
  ]) directions;

  workspaceBinds =
    lib.concatMap (entry: [
      (mkBind "ALT + ${entry.key}" "hl.dsp.focus({ workspace = ${toString entry.workspace} })")
      (mkBind "ALT + SHIFT + ${entry.key}" "hl.dsp.window.move({ workspace = ${toString entry.workspace}, follow = false })")
    ]) workspaceKeys
    ++ [
      (mkBind "ALT + CTRL + c" ''hl.dsp.window.move({ workspace = "empty", follow = true })'')
    ];

  movementBinds = lib.concatMap (entry: [
    (mkBind "ALT + SHIFT + ${entry.key}" "hl.dsp.window.move({ direction = \"${entry.direction}\" })")
    (mkBind "ALT + CTRL + ${entry.key}" "hl.dsp.window.resize({ x = ${toString entry.x}, y = ${toString entry.y}, relative = true })")
    (mkBind "ALT + ALT + ${entry.key}" "hl.dsp.window.move({ x = ${toString entry.x}, y = ${toString entry.y}, relative = true })")
  ]) directions;

  backendHardwareBinds = lib.optionals (config.zac.desktop.shell.backend == "legacy") [
    (mkBind "ALT + S" (exec "brightnessctl set 5%-"))
    (mkBind "ALT + A" (exec "brightnessctl set 5%+"))
  ];

  utilityBinds = [
    (mkBind "ALT + SHIFT + S" "hl.dsp.dpms({})")
    (mkBind "ALT + SHIFT + Escape" (exec "power-menu"))
    (mkBind "Print" (exec "screenshot --copy"))

    (mkBind "ALT + CTRL + R" (exec "record-lando-video"))
    (mkBind "ALT + CTRL + T" (exec "get-lando-thumbnail"))
    (mkBind "ALT + CTRL + S" (exec "get-lando-screenshot"))
    (mkBind "ALT + CTRL + bracketleft" (exec "record-lando-prev"))
    (mkBind "ALT + CTRL + bracketright" (exec "record-lando-next"))

    (mkBind "XF86AudioPlay" (exec "playerctl play-pause"))
    (mkBind "XF86AudioNext" (exec "playerctl next"))
    (mkBind "XF86AudioPrev" (exec "playerctl previous"))
    (mkBind "XF86AudioStop" (exec "playerctl stop"))
    (mkBind "ALT + semicolon" (exec "playerctl play-pause"))
    (mkBind "ALT + mouse_down" ''hl.dsp.focus({ workspace = "e-1" })'')
    (mkBind "ALT + mouse_up" ''hl.dsp.focus({ workspace = "e+1" })'')
    (mkBindWith "ALT + mouse:272" "hl.dsp.window.drag()" { mouse = true; })
    (mkBindWith "ALT + mouse:273" "hl.dsp.window.resize()" { mouse = true; })
  ]
  ++ backendHardwareBinds;
in
{
  wayland.windowManager.hyprland.settings = {
    config.binds.movefocus_cycles_fullscreen = true;
    bind =
      applicationBinds ++ windowBinds ++ focusBinds ++ workspaceBinds ++ movementBinds ++ utilityBinds;
  };
}
