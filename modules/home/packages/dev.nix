{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ## Lsp
    nixd # nix

    ## formating
    shfmt
    treefmt
    nixfmt

    ## C / C++
    gcc
    gdb
    gef
    cmake
    gnumake
    valgrind
    llvmPackages_20.clang-tools

    ## Android
    android-studio
    android-tools # adb, fastboot

    # Electron/GUI App Dependencies
    gtk3
    nss
    alsa-lib
  ];
}
