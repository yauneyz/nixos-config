{ ... }:
{
  # The bar uses its own translucent surfaces and module hierarchy while still
  # consuming the shared Stylix palette in style.nix.
  stylix.targets.waybar.enable = false;

  programs.waybar = {
    enable = true;
  };
}
