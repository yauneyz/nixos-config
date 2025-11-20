{ config, pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    # Wrap Emacs with HiDPI environment variables for better scaling
    (pkgs.writeShellScriptBin "emacs" ''
      export GDK_SCALE=1.5
      export GDK_DPI_SCALE=2.0  # Compensate for GDK_SCALE to avoid double-scaling fonts
      exec ${pkgs.emacs}/bin/emacs "$@"
    '')
  ];

  # Also provide unwrapped emacs binary as emacs-unwrapped if needed
  home.shellAliases = {
    emacs-unwrapped = "${pkgs.emacs}/bin/emacs";
  };
}
