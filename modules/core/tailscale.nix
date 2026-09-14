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
        # Runs `tailscale set --ssh` on every boot/activation so the Tailscale
        # SSH server is on declaratively on both hosts, in either direction.
        # Previously this only came from running `enable-ssh-tunnel` by hand,
        # so a re-auth or a fresh install silently lost it. `set` (unlike
        # `up`) applies without an auth key, so interactive login still owns
        # authentication.
        extraSetFlags = [ "--ssh" ];
      };

  # Cross-host SSH (e.g. laptop -> desktop for ML workloads) rides Tailscale's
  # built-in SSH server rather than OpenSSH: no authorized_keys to maintain,
  # nothing to expose on the LAN. Client-side host aliases live in
  # modules/home/ssh.nix.
}
