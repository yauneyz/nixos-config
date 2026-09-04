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
}
