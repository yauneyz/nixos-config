{ pkgs, ... }:
{
  home.packages = with pkgs; [
    discord
    (vesktop.override { electron_40 = electron_42; })
  ];
}
