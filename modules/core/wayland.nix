{ lib, pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
  };

  # nixpkgs' programs.hyprland adds security.wrappers.Hyprland with
  # cap_sys_nice+ep so Hyprland can self-assign SCHED_RR on startup. The NixOS
  # wrapper raises that cap into the *ambient* set, which then leaks into every
  # child process (terminals -> Steam -> srt-bwrap), making bwrap abort with
  # "Unexpected capabilities but not setuid". Neutralize the wrapper: Hyprland
  # just won't get realtime scheduling (rtkit still covers audio), and Steam/
  # Flatpak sandboxes work again. See nixpkgs PR #507419, issue #526193.
  security.wrappers.Hyprland.capabilities = lib.mkForce "";

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

    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];
  };
}
