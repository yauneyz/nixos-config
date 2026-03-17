{ lib, pkgs, username, ... }:
{
  # Add user to libvirtd group
  users.users.${username}.extraGroups = [ "kvm" "libvirtd" ];

  # Install necessary packages
  environment.systemPackages = with pkgs; [
    qemu_kvm
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    virtiofsd
    virtio-win
    win-spice
    adwaita-icon-theme
  ];

  # Manage the virtualisation services
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = false;
        swtpm.enable = true;
        vhostUserPackages = [ pkgs.virtiofsd ];
      };
    };
    spiceUSBRedirection.enable = true;
  };
  services.spice-vdagentd.enable = true;

  # libvirt 12.1 ships this unit with /usr/bin/sh, which does not exist on NixOS.
  # Force a Nix store shell and explicit binary paths so the unit can initialize.
  systemd.services.virt-secret-init-encryption.serviceConfig.ExecStart = lib.mkForce [
    ""
    "${pkgs.runtimeShell} -c 'umask 0077 && (${pkgs.coreutils}/bin/dd if=/dev/random status=none bs=32 count=1 | ${pkgs.systemd}/bin/systemd-creds encrypt --name=secrets-encryption-key - /var/lib/libvirt/secrets/secrets-encryption-key)'"
  ];
}
