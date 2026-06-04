{ ... }:
{
  programs.zathura = {
    enable = true;

    options = {
      # UI colors (statusbar, inputbar, completion, etc.) and the
      # recolor-light/darkcolor pair are set by Stylix from the active
      # base16 scheme (gruvbox-dark-hard). See modules/core/stylix.nix.

      # Render documents in dark mode by default (invert page colors).
      # Toggle at runtime with Ctrl+R.
      recolor = true;
      # Keep image/figure hues sane while recoloring text.
      recolor-keephue = true;

      # Quality-of-life
      selection-clipboard = "clipboard"; # yank to system clipboard
      adjust-open = "best-fit"; # fit page to window on open
      statusbar-home-tilde = true; # show ~ instead of /home/zac
      window-title-basename = true; # window title = file name only
      scroll-page-aware = true;
      smooth-scroll = true;
    };
  };
}
