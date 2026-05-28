{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    ## Utils
    # gamemode
    # gamescope
    # winetricks
    # inputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system}.wine-ge
    r2modman

    ## Minecraft
    # prismlauncher

    ## Cli games
    _2048
    _2048-in-terminal
    vitetris
    nethack

    ## Celeste
    # olympus
    # celeste-classic
    # celeste-classic-pm

    ## Doom
    # gzdoom
    crispy-doom

    ## Emulation
    sameboy
    snes9x
    cemu
    (symlinkJoin {
      name = "ryubing-wrapped";
      paths = [ ryubing ];
      buildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/Ryujinx \
          --set GDK_BACKEND x11
      '';
    })
    dolphin-emu
    simple64
  ];
}
