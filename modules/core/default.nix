{ ... }:
{
  imports = [
    ./nixpkgs.nix
    ./bootloader.nix
    ./hardware.nix
    ./xserver.nix
    ./network.nix
    ./nh.nix
    ./stylix.nix
    ./pipewire.nix
    ./program.nix
    ./security.nix
    ./services.nix
    ./syncthing.nix
    ./steam.nix
    ./system.nix
    ./flatpak.nix
    ./user.nix
    ./wayland.nix
    ./virtualization.nix
    #./focusd.nix
    #./vr.nix
  ];
}
