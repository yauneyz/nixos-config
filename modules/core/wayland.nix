{ lib, pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
  };

  # NixOS xdg-open switches to portal mode when this variable is non-empty.
  # Our current portal backends do not expose OpenURI, so keep it empty.
  environment.sessionVariables.NIXOS_XDG_OPEN_USE_PORTAL = lib.mkForce "";

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = lib.mkForce false;
    config = {
      common.default = [ "gtk" ];
      hyprland.default = [
        "gtk"
        "hyprland"
      ];
    };

    # programs.hyprland already adds its portalPackage; listing
    # pkgs.xdg-desktop-portal-hyprland too yields a second derivation and a
    # duplicate xdg-desktop-portal-hyprland.service in user-units.
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };
}
