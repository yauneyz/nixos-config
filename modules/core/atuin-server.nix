{ host, lib, ... }:
let
  port = 8888;
in
lib.mkIf (host == "desktop") {
  # Self-hosted atuin sync server for shell history (desktop <-> laptop).
  # History is end-to-end encrypted client-side; the server only stores
  # ciphertext. Reachable over Tailscale only.
  services.atuin = {
    enable = true;
    host = "0.0.0.0";
    inherit port;
    # Only tailnet peers can reach the port, and only one account is needed.
    openRegistration = true;
    database.createLocally = true;
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];
}
