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
          --set GDK_DPI_SCALE 2.0
      '';
    })
  ];

  # Also provide unwrapped emacs binary as emacs-unwrapped if needed
  home.shellAliases = {
    emacs-unwrapped = "${pkgs.emacs}/bin/emacs";
  };
}
