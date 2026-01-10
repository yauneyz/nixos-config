{ config, pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    # Wrap the real Emacs binary so we retain emacsclient and other tools
    (pkgs.symlinkJoin {
      name = "emacs-hidpi";
      paths = [ pkgs.emacs ];
      buildInputs = [ pkgs.makeWrapper pkgs.wl-clipboard ];
      postBuild = ''
        wrapProgram $out/bin/emacs \
          --set GDK_SCALE 1.5 \
          --set GDK_DPI_SCALE 2.0 \
          --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.pkg-config pkgs.gcc pkgs.gnumake ]} \
          --prefix PKG_CONFIG_PATH : "${pkgs.enchant2.dev}/lib/pkgconfig"
      '';
    })

    # Dependencies for Emacs packages
    # Jinx spell-checking requirements (for native module compilation)
    pkg-config            # Required for jinx compilation
    gcc                   # C compiler for building native modules
    gnumake               # Build tool
    enchant2              # Runtime library (also in cli.nix)
    enchant2.dev          # Development headers - CRITICAL for pkg-config!
    aspell                # Spell checker backend for enchant
    aspellDicts.en        # English dictionary
    aspellDicts.en-computers  # Computer terms dictionary
    aspellDicts.en-science    # Scientific terms dictionary

    # Other useful Emacs dependencies
    multimarkdown         # For markdown-mode preview
    pandoc                # For markdown export
    ripgrep               # Already in cli.nix, used by deadgrep/consult
  ];

  # Also provide unwrapped emacs binary as emacs-unwrapped if needed
  home.shellAliases = {
    emacs-unwrapped = "${pkgs.emacs}/bin/emacs";
  };
}
