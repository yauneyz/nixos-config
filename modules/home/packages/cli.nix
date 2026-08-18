{ pkgs, inputs, ... }:
let
  # codex-cli-nix now packages the "code mode" host binary and wrapper itself.
  # Supply a non-deprecated platform alias until its remaining stdenv.isLinux
  # checks switch to stdenv.hostPlatform.isLinux.
  codexStdenv = pkgs.stdenv // {
    isLinux = pkgs.stdenv.hostPlatform.isLinux;
  };
  codexLatest =
    (inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default).override
      { stdenv = codexStdenv; };
in
{
  home.packages = with pkgs; [
    ## Better core utils
    duf                               # disk information
    eza                               # ls replacement
    fd                                # find replacement
    gping                             # ping with a graph
    gtrash                            # rm replacement, put deleted files in system trash
    hexyl                             # hex viewer
    man-pages                         # extra man pages
    dust                              # disk usage tree
    ncdu                              # disk space
    ripgrep                           # grep replacement
    python3Packages.grip              # GitHub Markdown preview
    tldr

    ## Coding agents
    antigravity-cli
    claude-code
    codexLatest                       # codex CLI (fast-updating flake)
    bubblewrap                        # bwrap: sandbox backend codex looks for on PATH

    ## Tools / useful cli
    aoc-cli                           # Advent of Code command-line tool
    awscli2
    azure-cli
    asciinema
    asciinema-agg
    binsider
    bitwise                           # cli tool for bit / hex manipulation
    broot                             # tree files view
    caligula                          # User-friendly, lightweight TUI for disk imaging
    hyperfine                         # benchmarking tool
    pastel                            # cli to manipulate colors
    scooter                           # Interactive find and replace in the terminal
    stripe-cli                        # Stripe CLI
    swappy                            # snapshot editing tool
    tdf                               # cli pdf viewer
    tokei                             # project line counter
    translate-shell                   # cli translator
    woomer
    yt-dlp-light

    ## TUI
    epy                               # ebook reader
    glow                              # Markdown reader
    gtt                               # google translate TUI
    programmer-calculator
    toipe                             # typing test in the terminal
    ttyper                            # cli typing test

    ## Monitoring / fetch
    htop
    onefetch                          # fetch utility for git repo
    wavemon                           # monitoring for wireless network devices

    ## Fun / screensaver
    asciiquarium-transparent
    cbonsai
    cmatrix
    countryfetch
    cowsay
    figlet
    fortune
    lavat
    lolcat
    pipes
    sl
    tty-clock

    ## Multimedia
    imv
    lowfi
    # mpv managed declaratively in ../mpv.nix

    ## Utilities
    entr                              # perform action when file change
    enchant_2                         # spellchecking utilities
    ffmpeg
    file                              # Show file information
    firebase-tools                    # Firebase CLI
    heroku                            # Heroku CLI
    (writeShellApplication {
      name = "vercel";
      runtimeInputs = [
        nodejs_22
        pnpm
      ];
      text = ''
        exec pnpm dlx vercel@54.21.1 "$@"
      '';
    })
    caffeine-ng                       # Tray toggle to inhibit screensaver/sleep
    fpm                               # Effing Package Management
    jq                                # JSON processor
    killall
    libnotify
    mimeo
    openssl
    pamixer                           # pulseaudio command line mixer
    playerctl                         # controller for media players
    postgresql                        # PostgreSQL client tools (psql, etc.)
    poweralertd
    powershell                        # pwsh: electron-builder's native Azure Trusted Signing
                                       # (Invoke-TrustedSigning) needs it + wine to cross-sign
                                       # Windows installers from Linux (snorlax release:upload:win)
    slurp                             # select region on screen (Wayland)
    grim                              # screenshot utility (Wayland)
    udiskie                           # Automounter for removable media
    unzip
    wget
    wl-clipboard                      # clipboard utils for wayland (wl-copy, wl-paste)
    xdg-utils

    winetricks
    wineWow64Packages.waylandFull
    dpkg                              # dpkg-scanpackages: signed APT repo publishing (snorlax release:both)
  ];
}
