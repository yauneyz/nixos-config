{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.focusd;
in {
  options.services.focusd = {
    enable = mkEnableOption "focusd distraction blocker daemon";

    package = mkOption {
      type = types.package;
      default = pkgs.focusd;
      defaultText = literalExpression "pkgs.focusd";
      description = "The focusd package to use.";
    };

    tokenHashFile = mkOption {
      type = types.path;
      description = ''
        Path to the USB key token hash file (token.sha256).
        This file contains the SHA256 hash of your USB authentication key.
      '';
    };

    refreshIntervalMinutes = mkOption {
      type = types.int;
      default = 60;
      description = "How often to refresh IP addresses (in minutes)";
    };

    usbKeyPath = mkOption {
      type = types.str;
      default = "/run/media/zac/*/FOCUSD/focusd.key";
      description = "Glob pattern for finding the USB key file";
    };
  };

  config = mkIf cfg.enable {
    # Enable nftables
    networking.nftables.enable = true;

    # Install the package system-wide
    environment.systemPackages = [ cfg.package ];

    # Create config directory and files
    environment.etc = {
      "focusd/token.sha256" = {
        source = cfg.tokenHashFile;
      };

      "focusd/config.yaml" = {
        text = ''
          # focusd system configuration
          # Blocklist is managed by user at: ~/.config/focusd/blocklist.yml
          # See: ${cfg.package}/share/doc/blocklist.example.yml

          refreshIntervalMinutes: ${toString cfg.refreshIntervalMinutes}
          usbKeyPath: "${cfg.usbKeyPath}"
          tokenHashPath: "/etc/focusd/token.sha256"
          dnsmasqConfigPath: "/run/focusd/dnsmasq.conf"
        '';
      };
    };

    # State and runtime directories
    systemd.tmpfiles.rules = [
      "d /var/lib/focusd 0750 root root -"
      "d /run/focusd 0755 root root -"
    ];

    # Configure dnsmasq to use our config directory
    services.dnsmasq = {
      enable = true;
      settings = {
        # Use conf-dir to ADD our config, not replace dnsmasq's config
        conf-dir = [ "/run/focusd" ];
      };
    };

    # Main focusd daemon service
    systemd.services.focusd = {
      description = "focusd - Distraction blocker daemon";
      documentation = [ "https://github.com/yauneyz/focusd" ];
      after = [ "network-online.target" "nftables.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      # Ensure network tools are in PATH for transparent proxy setup
      path = with pkgs; [ nftables iproute2 ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/focusd daemon --config /etc/focusd/config.yaml";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "on-failure";
        RestartSec = "10s";

        # Security hardening
        User = "root";  # Required for nftables, dnsmasq, and transparent proxy
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";  # Need to read user's blocklist at ~/.config/focusd/
        ReadWritePaths = [
          "/var/lib/focusd"
          "/run/focusd"
        ];
        PrivateTmp = true;

        # Transparent proxy needs network admin capabilities
        # This allows setting up TPROXY rules and routing tables
        AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
        CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
      };
    };

    # Reload dnsmasq when focusd config changes
    systemd.services.dnsmasq = {
      partOf = [ "focusd.service" ];
      after = [ "focusd.service" ];
    };
  };
}
