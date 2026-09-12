{ pkgs, ... }:
{
  services.sunshine = {
    enable = true;
    autoStart = true;
    openFirewall = true;

    # Build only Sunshine with CUDA support. Global CUDA support remains off,
    # avoiding CUDA variants of unrelated packages while enabling the RTX
    # 4090's low-latency NVENC path.
    package = pkgs.sunshine.override { cudaSupport = true; };

    # Hyprland exposes the wlroots screencopy protocol, so Sunshine can capture
    # the desktop without the root-equivalent CAP_SYS_ADMIN required by KMS.
    settings = {
      capture = "wlr";
      encoder = "nvenc";
      # Current wlroots capture selects reliably by stable Wayland output name;
      # numeric IDs are only honored by the encoder probe in this release.
      output_name = "DP-2";
    };
  };

  # Allow Moonlight controllers, keyboards, and mice to be forwarded through
  # Sunshine. The Sunshine NixOS module enables the uinput kernel support.
  users.users.zac.extraGroups = [
    "i2c"
    "uinput"
  ];

  # DDC/CI brightness control darkens the physical panels without disabling
  # the Wayland outputs that Sunshine captures.
  hardware.i2c.enable = true;

  # Linux virtual Xbox/PlayStation controllers use uhid in addition to uinput.
  # Keep the node private to the uinput group and the active local session.
  services.udev.extraRules = ''
    SUBSYSTEM=="misc", KERNEL=="uhid", MODE="0660", GROUP="uinput", TAG+="uaccess"
  '';
}
