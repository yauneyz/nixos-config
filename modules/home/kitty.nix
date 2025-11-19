{ host, config, ... }:
{
  programs.kitty = {
    enable = true;

    # Theme managed by Stylix
    # themeFile = "gruvbox-dark-hard";

    font = {
      name = config.stylix.fonts.monospace.name;
      size = if (host == "laptop") then 15 else 16;
    };

    extraConfig = ''
      font_features MapleMono-Regular +ss01 +ss02 +ss04
      font_features MapleMono-Bold +ss01 +ss02 +ss04
      font_features MapleMono-Italic +ss01 +ss02 +ss04
      font_features MapleMono-Light +ss01 +ss02 +ss04
    '';

    settings = {
      confirm_os_window_close = 0;
      # background_opacity is set by Stylix
      scrollback_lines = 10000;
      enable_audio_bell = false;
      mouse_hide_wait = 60;
      window_padding_width = if (host == "laptop") then 5 else 10;

      ## Tabs
      tab_title_template = "{index}";
      active_tab_font_style = "normal";
      inactive_tab_font_style = "normal";
      tab_bar_style = "powerline";
      tab_powerline_style = "angled";
      # Tab colors managed by Stylix
    };

    keybindings = {
      ## Tabs
      "alt+1" = "goto_tab 1";
      "alt+2" = "goto_tab 2";
      "alt+3" = "goto_tab 3";
      "alt+4" = "goto_tab 4";

      ## Unbind
      "ctrl+shift+left" = "no_op";
      "ctrl+shift+right" = "no_op";
    };
  };
}
