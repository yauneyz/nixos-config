{ pkgs, ... }:
{
  # Terminal file manager. `y` opens it and cd's into wherever you quit
  # (q = quit and cd, Q = quit without cd).
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";

    # Previewers: PDFs (pdftoppm), SVG, images, video thumbnails, archives.
    extraPackages = with pkgs; [
      poppler-utils
      resvg
      imagemagick
      ffmpeg
      _7zz
      ouch
      jq
      fd
      ripgrep
      fzf
      zoxide
    ];

    plugins = {
      inherit (pkgs.yaziPlugins)
        git
        ouch
        full-border
        smart-enter
        chmod
        toggle-pane
        ;
    };

    initLua = ''
      require("full-border"):setup()
      require("git"):setup()
    '';

    settings = {
      mgr = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
        linemode = "size";
        show_symlink = true;
      };
      preview = {
        max_width = 1600;
        max_height = 1600;
      };
      plugin = {
        # Git status column in file listings.
        prepend_fetchers = [
          {
            group = "git";
            url = "*";
            run = "git";
          }
          {
            group = "git";
            url = "*/";
            run = "git";
          }
        ];
        # Preview archive contents instead of a hex dump.
        prepend_previewers = [
          {
            mime = "application/{*zip,tar,bzip2,7z*,rar,xz,zstd,java-archive}";
            run = "ouch";
          }
        ];
      };
    };

    keymap.mgr.prepend_keymap = [
      {
        on = "l";
        run = "plugin smart-enter";
        desc = "Enter dir or open file";
      }
      {
        on = "<Enter>";
        run = "plugin smart-enter";
        desc = "Enter dir or open file";
      }
      {
        on = "C";
        run = "plugin ouch";
        desc = "Compress selection (ouch)";
      }
      {
        on = [
          "c"
          "m"
        ];
        run = "plugin chmod";
        desc = "chmod selection";
      }
      {
        on = "T";
        run = "plugin toggle-pane max-preview";
        desc = "Maximize/restore preview";
      }
    ];
  };
}
