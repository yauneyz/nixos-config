{ pkgs, ... }:
{
  programs.bat = {
    enable = true;
    config = {
      pager = "less -FR";
      # theme is set by Stylix
    };
    extraPackages = with pkgs.bat-extras; [
      batman
      batpipe
      # batgrep
      # batdiff
    ];
  };
}
