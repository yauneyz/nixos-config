{ host, lib, ... }:
{
  services.tailscale =
    lib.mkIf
      (builtins.elem host [
        "desktop"
        "laptop"
      ])
      {
        enable = true;
        # Improves the chance of a low-latency direct connection instead of DERP
        # relay traffic. Authentication is deliberately completed interactively.
        openFirewall = true;
      };

  # Cross-host SSH (e.g. laptop -> desktop for ML workloads) rides Tailscale's
  # built-in SSH server rather than OpenSSH: no authorized_keys to maintain,
  # nothing to expose on the LAN. Run `enable-ssh-tunnel` once per machine
  # (see modules/home/scripts/scripts/enable-ssh-tunnel.sh) to turn it on.
}
