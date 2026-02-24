{ pkgs, inputs, ... }:
let
  codexOriginal = inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;
  codexLatest = pkgs.stdenv.mkDerivation {
    name = "codex-patched";
    src = codexOriginal;
    dontUnpack = true;

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [
      pkgs.libcap.lib
      pkgs.openssl
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
    ];

    installPhase = ''
      mkdir -p $out/bin
      # Copy the actual binary
      cp $src/bin/codex-raw $out/bin/codex-raw
      # Create a new wrapper that points to our patched binary
      cat > $out/bin/codex <<EOF
      #!/usr/bin/env bash
      export CODEX_EXECUTABLE_PATH="\$HOME/.local/bin/codex"
      export DISABLE_AUTOUPDATER=1
      exec "$out/bin/codex-raw" "\$@"
      EOF
      chmod +x $out/bin/codex
    '';
  };
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
    ncdu                              # disk space
    ripgrep                           # grep replacement
    grip                              # GitHub Markdown preview
    tldr

    ## Coding agents
    gemini-cli
    claude-code
    codexLatest                       # codex CLI (fast-updating flake)

    ## Tools / useful cli
    aoc-cli                           # Advent of Code command-line tool
    awscli2
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
    mpv

    ## Utilities
    entr                              # perform action when file change
    enchant_2                         # spellchecking utilities
    ffmpeg
    file                              # Show file information
    firebase-tools                    # Firebase CLI
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
    slurp                             # select region on screen (Wayland)
    grim                              # screenshot utility (Wayland)
    udiskie                           # Automounter for removable media
    unzip
    wget
    wl-clipboard                      # clipboard utils for wayland (wl-copy, wl-paste)
    xdg-utils

    winetricks
    wineWowPackages.waylandFull
  ];
}
