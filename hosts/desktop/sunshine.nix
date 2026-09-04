{ ... }:
{
  services.sunshine = {
    enable = true;
    autoStart = true;
    openFirewall = true;

    # Hyprland exposes the wlroots screencopy protocol, so Sunshine can capture
    # the desktop without the root-equivalent CAP_SYS_ADMIN required by KMS.
    settings = {
      capture = "wlr";
      encoder = "nvenc";
    };
  };

  # Allow Moonlight controllers, keyboards, and mice to be forwarded through
  # Sunshine. The Sunshine NixOS module enables the uinput kernel support.
  users.users.zac.extraGroups = [ "uinput" ];
}
