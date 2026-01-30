{ ... }:
{
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
    ./languages                       # programming language tooling
    ./lazygit.nix
    ./micro.nix                       # nano replacement
    ./nautilus.nix                    # file manager
    ./nix-search/nix-search.nix       # TUI to search nixpkgs
    ./neovim                        # neovim editor
    ./obsidian.nix
    ./p10k/p10k.nix
    ./packages                        # other packages
    ./retroarch.nix
    ./rofi/rofi.nix                   # launcher
    ./scripts/scripts.nix             # personal scripts
    ./ssh.nix                         # ssh config
    ./superfile/superfile.nix         # terminal file manager
    ./swaylock.nix                    # lock screen
    ./swayosd.nix                     # brightness / volume wiget
    ./swaync/swaync.nix               # notification deamon
    ./vicinae.nix                     # launcher
    ./vscodium                        # vscode fork
    ./waybar                          # status bar
    # ./waypaper.nix                  # GUI wallpaper picker (replaced by Stylix)
    ./xresources.nix                  # X resources (xterm font, etc.)
    ./xdg-mimes.nix                   # xdg config
    ./zsh                             # shell
  ];
}
