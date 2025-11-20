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

    socketPath = mkOption {
      type = types.str;
      default = "/var/lib/focusd/daemon.sock";
      description = "Path to the daemon UNIX socket.";
    };

    logLevel = mkOption {
      type = types.enum [ "DEBUG" "INFO" "WARNING" "ERROR" ];
      default = "INFO";
      description = "Log level for the daemon.";
    };
  };

  config = mkIf cfg.enable {
    # Install the package system-wide and required dependencies
    environment.systemPackages = with pkgs; [
      cfg.package
      nftables
      iproute2
      conntrack-tools
    ];

    # Enable nftables
    networking.nftables.enable = true;

    # Create configuration directory
    environment.etc."focusd/.keep".text = "";

    # State and log directories
    systemd.tmpfiles.rules = [
      "d /var/lib/focusd 0755 root root -"
      "f /var/log/focusd.log 0644 root root -"
    ];

    # Main focusd daemon service
    systemd.services.focusd = {
      description = "Focus mode daemon - distraction blocker";
      documentation = [ "https://github.com/yauneyz/focusd" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/focusd";
        Restart = "on-failure";
        RestartSec = 5;

        # Security settings
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";

        # State directories
        StateDirectory = "focusd";
        LogsDirectory = "focusd";

        # Required capabilities for network manipulation
        AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
        CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];

        # Read-write paths - allow focusd to modify /etc/hosts directly
        ReadWritePaths = [
          "/etc/hosts"
          "/etc/focusd"
          "/var/lib/focusd"
          "/var/log/focusd.log"
        ];
      };
    };

    # Load required kernel modules
    boot.kernelModules = [ "nf_conntrack" "xt_TPROXY" "nf_nat" ];

    # Ensure required kernel parameters for transparent proxy
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv4.conf.all.route_localnet" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
  };
}
