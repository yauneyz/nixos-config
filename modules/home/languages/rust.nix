{ pkgs, ... }:
let
  rustToolchain = with pkgs.fenix; combine [
    stable.cargo
    stable.rustc
    stable.rustfmt
    stable.clippy
    targets.x86_64-pc-windows-msvc.stable.rust-std
  ];
in
{
  home.packages = with pkgs; [
    rustToolchain
    rust-analyzer
    cargo-xwin
  ];
}
