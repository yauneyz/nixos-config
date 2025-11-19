{ config, ... }:
let
  colors = config.lib.stylix.colors.withHashtag;
in
{
  programs.fzf = {
    enable = true;

    enableZshIntegration = true;

    defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
    fileWidgetOptions = [
      "--preview 'if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'"
    ];
    changeDirWidgetCommand = "fd --type=d --hidden --strip-cwd-prefix --exclude .git";
    changeDirWidgetOptions = [
      "--preview 'eza --tree --color=always {} | head -200'"
    ];

    ## Theme
    defaultOptions = [
      "--color=fg:-1,fg+:${colors.base05},bg:-1,bg+:${colors.base01}"
      "--color=hl:${colors.base0B},hl+:${colors.base0B},info:${colors.base04},marker:${colors.base09}"
      "--color=prompt:${colors.base08},spinner:${colors.base0C},pointer:${colors.base09},header:${colors.base0D}"
      "--color=border:${colors.base03},label:${colors.base04},query:${colors.base05}"
      "--border='double' --border-label='' --preview-window='border-sharp' --prompt='> '"
      "--marker='>' --pointer='>' --separator='─' --scrollbar='│'"
      "--info='right'"
      "--bind change:top"
    ];
  };
}
