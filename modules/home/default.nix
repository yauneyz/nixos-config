{ ... }:
{
  home.pointerCursor.enable = true;

  imports = [
    ./aseprite/aseprite.nix           # pixel art editor
    ./audacious/audacious.nix         # music player
    ./bat.nix                         # better cat command
    ./browser.nix                     # firefox based browser
    ./btop.nix                        # resouces monitor
    ./cava.nix                        # audio visualizer
    ./envars.nix                      # misc environment variables
    ./path.nix                        # custom PATH entries
    ./discord.nix                     # discord
    ./emacs.nix                       # emacs editor
    ./fastfetch/fastfetch.nix         # fetch tool
    ./fzf.nix                         # fuzzy finder
    ./gaming.nix                      # packages related to gaming
    ./ghostty/ghostty.nix             # terminal
    ./git.nix                         # version control
    ./gnome.nix                       # gnome apps
    ./gtk.nix                         # gtk theme
    ./hyprland                        # window manager
    ./kindle-sync.nix                 # opportunistic USB mirror of ~/Main to Kindle
    ./languages                       # programming language tooling
    ./lazygit.nix
    ./llm-roleplay.nix                # local roleplay model serving
    ./micro.nix                       # nano replacement
    ./mpv.nix                         # video player (scrubbing + reverse)
    ./nautilus.nix                    # file manager
    ./nix-search/nix-search.nix       # TUI to search nixpkgs
    ./neovim                        # neovim editor
    ./obs.nix                         # OBS tray icon config
    ./obsidian.nix
    ./p10k/p10k.nix
    ./packages                        # other packages
    ./quickshell                     # native desktop shell + legacy backend switch
    ./retroarch.nix
    ./rofi/rofi.nix                   # launcher
    ./scripts/scripts.nix             # personal scripts
    ./snorlax.nix                     # Talysman browser native-messaging host
    ./ssh.nix                         # ssh config
    ./storage.nix                     # keep large caches off the root filesystem
    ./superfile/superfile.nix         # terminal file manager
    ./swaylock.nix                    # lock screen
    ./swayosd.nix                     # brightness / volume wiget
    ./swaync/swaync.nix               # notification deamon
    ./symlinks.nix                    # host-aware data-home symlinks
    ./vicinae.nix                     # launcher
    ./vlc.nix                         # media player
    ./vscodium                        # vscode fork
    ./waybar                          # status bar
    # ./waypaper.nix                  # GUI wallpaper picker (replaced by Stylix)
    ./xresources.nix                  # X resources (xterm font, etc.)
    ./xdg-mimes.nix                   # xdg config
    ./zathura.nix                     # PDF / document viewer
    ./zsh                             # shell
  ];
}
