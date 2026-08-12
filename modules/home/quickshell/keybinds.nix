{ config, lib, ... }:
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
  wayland.windowManager.hyprland.settings.bind =
    lib.mkIf (config.zac.desktop.shell.backend == "quickshell")
      [
        (bind "ALT + CTRL + A" "zac-shell toggle audio" { })
        (bind "ALT + CTRL + B" "zac-shell toggle bluetooth" { })
        (bind "ALT + CTRL + N" "zac-shell toggle network" { })
        (bind "ALT + C" "zac-shell toggle calendar" { })
        (bind "ALT + SHIFT + N" "zac-shell notifications" { })
        (bind "ALT + Escape" "zac-shell close" { })
        (bind "ALT + SHIFT + R" "zac-shell reload" { })

        (bind "XF86AudioMute" "zac-shell audio mute" { locked = true; })
        (bind "XF86AudioMicMute" "zac-shell mic mute" { locked = true; })
        (bind "XF86AudioRaiseVolume" "zac-shell audio 0.02" {
          locked = true;
          repeating = true;
        })
        (bind "XF86AudioLowerVolume" "zac-shell audio -0.02" {
          locked = true;
          repeating = true;
        })
        (bind "ALT + f11" "zac-shell audio 0.02" {
          locked = true;
          repeating = true;
        })
        (bind "ALT + f12" "zac-shell audio -0.02" {
          locked = true;
          repeating = true;
        })
        (bind "XF86MonBrightnessUp" "zac-shell brightness 5" {
          locked = true;
          repeating = true;
        })
        (bind "XF86MonBrightnessDown" "zac-shell brightness -5" {
          locked = true;
          repeating = true;
        })
        (bind "ALT + S" "zac-shell brightness -5" { })
        (bind "ALT + A" "zac-shell brightness 5" { })
        (bind "CAPS + Caps_Lock" "zac-shell osd caps -1 Caps_Lock" { release = true; })
        (bind "Scroll_Lock" "zac-shell osd scroll -1 Scroll_Lock" { release = true; })
        (bind "Num_Lock" "zac-shell osd num -1 Num_Lock" { release = true; })
      ];
}
