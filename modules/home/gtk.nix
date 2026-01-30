{ pkgs, ... }:
{
  gtk = {
    enable = true;
    gtk3.extraConfig = {
      # Hint GTK3 apps to prefer a dark theme when available.
      gtk-application-prefer-dark-theme = 1;
    };
  };

  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    nerd-fonts.caskaydia-cove
    nerd-fonts.symbols-only
    twemoji-color-font
    noto-fonts-color-emoji
    fantasque-sans-mono
    maple-mono-custom
  ];

  dconf.settings."org/gnome/desktop/interface" = {
    # System-wide preference for dark mode (GTK4/libadwaita aware apps)
    color-scheme = "prefer-dark";
  };

  # GTK theming is now handled by Stylix (modules/core/stylix.nix)
}
