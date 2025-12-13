{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    binds = {
      movefocus_cycles_fullscreen = true;
    };

    bind = [
      # Terminal (i3: Mod1+t)
      "$mainMod, T, exec, ghostty --gtk-single-instance=true"

      # Application launchers (from i3)
      "$mainMod, I, exec, firefox"  # i3: Mod1+i
      "$mainMod, N, exec, nautilus"  # i3: Mod1+n (file manager)
      "$mainMod, M, exec, spotify"  # i3: Mod1+m
      "$mainMod, E, exec, emacs"  # i3: Mod1+e
      "$mainMod SHIFT, E, exec, restart-emacs-daemon.sh" # restart emacs daemon
      "$mainMod, D, exec, rofi -show drun"  # i3: Mod1+d (launcher)
      "$mainMod, Z, exec, toggle-monitor"

      # Bluetooth controls (from i3) - Connect/disconnect headphones
      "$mainMod, B, exec, bluetoothctl connect 94:DB:56:F7:A5:C7"  # i3: Mod1+b
      "$mainMod SHIFT, B, exec, bluetoothctl disconnect 94:DB:56:F7:A5:C7"  # i3: Mod1+Shift+b
      "$mainMod CTRL, B, exec, overskride"  # Open Overskride for BT management

      # Window management (from i3)
      "$mainMod SHIFT, Q, killactive,"  # i3: Mod1+Shift+q
      "$mainMod, F, fullscreen, 0"  # i3: Mod1+f
      "$mainMod, Space, togglefloating,"  # i3: Mod1+Space (floating toggle)

      # Split controls (from i3)
      "$mainMod, V, layoutmsg, preselect d"  # i3: Mod1+v (split vertical)
      "$mainMod SHIFT, V, layoutmsg, preselect r"  # i3: Mod1+Shift+v (split horizontal)

      # Scratchpad (from i3)
      "$mainMod, minus, togglespecialworkspace, scratchpad"  # i3: Mod1+minus (show)
      "$mainMod SHIFT, minus, movetoworkspace, special:scratchpad"  # i3: Mod1+Shift+minus

      # Workspace back and forth (from i3)
      "$mainMod, Tab, workspace, previous"  # i3: Mod1+Tab

      # Brightness controls (from i3)
      "$mainMod, S, exec, brightnessctl set 5%-"  # i3: Mod1+s
      "$mainMod, A, exec, brightnessctl set 5%+"  # i3: Mod1+a

      # Utility bindings (from i3)
      "$mainMod SHIFT, S, exec, hyprctl dispatch dpms toggle"  # i3: Mod1+Shift+s (screen sleep toggle)

      # Power menu
      "$mainMod SHIFT, Escape, exec, power-menu"

      # Screenshot (i3: Print key)
      ",Print, exec, screenshot --copy"

      # switch focus
      "$mainMod, left,  movefocus, l"
      "$mainMod, right, movefocus, r"
      "$mainMod, up,    movefocus, u"
      "$mainMod, down,  movefocus, d"
      "$mainMod, h, movefocus, l"
      "$mainMod, j, movefocus, d"
      "$mainMod, k, movefocus, u"
      "$mainMod, l, movefocus, r"

      "$mainMod, left,  alterzorder, top"
      "$mainMod, right, alterzorder, top"
      "$mainMod, up,    alterzorder, top"
      "$mainMod, down,  alterzorder, top"
      "$mainMod, h, alterzorder, top"
      "$mainMod, j, alterzorder, top"
      "$mainMod, k, alterzorder, top"
      "$mainMod, l, alterzorder, top"

      "CTRL ALT, up, exec, hyprctl dispatch focuswindow floating"
      "CTRL ALT, down, exec, hyprctl dispatch focuswindow tiled"

      # switch workspace
      "$mainMod, 1, workspace, 1"
      "$mainMod, 2, workspace, 2"
      "$mainMod, 3, workspace, 3"
      "$mainMod, 4, workspace, 4"
      "$mainMod, 5, workspace, 5"
      "$mainMod, 6, workspace, 6"
      "$mainMod, 7, workspace, 7"
      "$mainMod, 8, workspace, 8"
      "$mainMod, 9, workspace, 9"
      "$mainMod, 0, workspace, 10"
      "$mainMod, w, workspace, 11"
      "$mainMod, y, workspace, 12"
      "$mainMod, u, workspace, 13"
      "$mainMod, o, workspace, 14"
      "$mainMod, p, workspace, 15"

      # same as above, but switch to the workspace
      "$mainMod SHIFT, 1, movetoworkspacesilent, 1" # movetoworkspacesilent
      "$mainMod SHIFT, 2, movetoworkspacesilent, 2"
      "$mainMod SHIFT, 3, movetoworkspacesilent, 3"
      "$mainMod SHIFT, 4, movetoworkspacesilent, 4"
      "$mainMod SHIFT, 5, movetoworkspacesilent, 5"
      "$mainMod SHIFT, 6, movetoworkspacesilent, 6"
      "$mainMod SHIFT, 7, movetoworkspacesilent, 7"
      "$mainMod SHIFT, 8, movetoworkspacesilent, 8"
      "$mainMod SHIFT, 9, movetoworkspacesilent, 9"
      "$mainMod SHIFT, 0, movetoworkspacesilent, 10"
      "$mainMod SHIFT, w, movetoworkspacesilent, 11"
      "$mainMod SHIFT, y, movetoworkspacesilent, 12"
      "$mainMod SHIFT, u, movetoworkspacesilent, 13"
      "$mainMod SHIFT, o, movetoworkspacesilent, 14"
      "$mainMod SHIFT, p, movetoworkspacesilent, 15"
      "$mainMod CTRL, c, movetoworkspace, empty"

      # window control
      "$mainMod SHIFT, left, movewindow, l"
      "$mainMod SHIFT, right, movewindow, r"
      "$mainMod SHIFT, up, movewindow, u"
      "$mainMod SHIFT, down, movewindow, d"
      "$mainMod SHIFT, h, movewindow, l"
      "$mainMod SHIFT, j, movewindow, d"
      "$mainMod SHIFT, k, movewindow, u"
      "$mainMod SHIFT, l, movewindow, r"

      "$mainMod CTRL, left, resizeactive, -80 0"
      "$mainMod CTRL, right, resizeactive, 80 0"
      "$mainMod CTRL, up, resizeactive, 0 -80"
      "$mainMod CTRL, down, resizeactive, 0 80"
      "$mainMod CTRL, h, resizeactive, -80 0"
      "$mainMod CTRL, j, resizeactive, 0 80"
      "$mainMod CTRL, k, resizeactive, 0 -80"
      "$mainMod CTRL, l, resizeactive, 80 0"

      "$mainMod ALT, left, moveactive,  -80 0"
      "$mainMod ALT, right, moveactive, 80 0"
      "$mainMod ALT, up, moveactive, 0 -80"
      "$mainMod ALT, down, moveactive, 0 80"
      "$mainMod ALT, h, moveactive,  -80 0"
      "$mainMod ALT, j, moveactive, 0 80"
      "$mainMod ALT, k, moveactive, 0 -80"
      "$mainMod ALT, l, moveactive, 80 0"

      # media and volume controls (from i3)
      ",XF86AudioMute, exec, playerctl volume 0.0"
      ",XF86AudioRaiseVolume, exec, playerctl volume 0.05+"
      ",XF86AudioLowerVolume, exec, playerctl volume 0.05-"
      ",XF86AudioPlay, exec, playerctl play-pause"
      ",XF86AudioNext, exec, playerctl next"
      ",XF86AudioPrev, exec, playerctl previous"
      ",XF86AudioStop, exec, playerctl stop"
      "$mainMod, semicolon, exec, playerctl play-pause"  # i3: Mod1+semicolon

      # brightness controls with media keys
      ",XF86MonBrightnessUp, exec, swayosd-client --brightness raise"
      ",XF86MonBrightnessDown, exec, swayosd-client --brightness lower"

      "$mainMod, mouse_down, workspace, e-1"
      "$mainMod, mouse_up, workspace, e+1"

      # clipboard manager
      "$mainMod, V, exec, vicinae vicinae://extensions/vicinae/clipboard/history"
    ];

    # mouse binding
    bindm = [
      "$mainMod, mouse:272, movewindow"
      "$mainMod, mouse:273, resizewindow"
    ];
  };
}
