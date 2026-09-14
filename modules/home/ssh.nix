{ ... }:
{
  programs.ssh = {
    enable = true;

    enableDefaultConfig = false;

    settings = {
      "*" = {
        addKeysToAgent = "1h";

        controlMaster = "auto";
        controlPath = "~/.ssh/control-%r@%h:%p";
        controlPersist = "10m";

        forwardAgent = false;
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
      };

      # Tailnet peers, pinned to their 100.x addresses (from `tailscale status`)
      # so `ssh desktop` / `ssh laptop` work even when MagicDNS resolution is
      # unavailable. Auth is Tailscale SSH (see modules/core/tailscale.nix), so
      # there is no key to name here. accept-new records the host key that
      # tailscaled generates on first connect instead of failing the TOFU
      # prompt, which is what blocked desktop -> laptop.
      desktop = {
        HostName = "100.72.178.46";
        User = "zac";
        StrictHostKeyChecking = "accept-new";
      };

      laptop = {
        HostName = "100.125.151.115";
        User = "zac";
        StrictHostKeyChecking = "accept-new";
      };

      github = {
        host = "github.com";
        hostname = "github.com";
        user = "git";
        port = 22;
        identityFile = "~/.ssh/id_github";
        identitiesOnly = true;
      };
    };
  };

  services.ssh-agent.enable = true;
}
