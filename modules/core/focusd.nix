{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.focusd;
  focusd = pkgs.callPackage ../../packages/focusd { };

  # Generate base /etc/hosts from NixOS configuration
  baseHostsFile = pkgs.writeText "nixos-base-hosts" ''
    # NixOS generated base hosts file
    127.0.0.1 localhost
    ::1 localhost ip6-localhost ip6-loopback
    fe00::0 ip6-localnet
    ff00::0 ip6-mcastprefix
    ff02::1 ip6-allnodes
    ff02::2 ip6-allrouters
    ff02::3 ip6-allhosts

    ${optionalString (config.networking.hostName != "") ''
    127.0.1.1 ${config.networking.hostName}
    ''}

    ${concatStringsSep "\n" (mapAttrsToList (host: addresses:
      concatStringsSep "\n" (map (addr: "${addr} ${host}") addresses)
    ) config.networking.hosts)}

    ${config.networking.extraHosts}
  '';

in {
  options.services.focusd = {
    enable = mkEnableOption "focusd distraction blocker daemon";

    package = mkOption {
      type = types.package;
      default = focusd;
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

    # Create configuration directory and copy base hosts
    environment.etc = {
      "focusd/.keep".text = "";
      "nixos-base-hosts".source = baseHostsFile;
    };

    # State and log directories
    systemd.tmpfiles.rules = [
      "d /var/lib/focusd 0755 root root -"
      "f /var/log/focusd.log 0644 root root -"
      "f /var/lib/focusd/hosts-additions 0644 root root -"
      "f /var/lib/focusd/firefox-excluded-domains 0644 root root -"
      "d /etc/firefox/pref 0755 root root -"
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

        # Read-write paths
        ReadWritePaths = [
          "/etc/hosts"
          "/etc/focusd"
          "/etc/firefox/pref"
          "/var/lib/focusd"
          "/var/log/focusd.log"
        ];
      };

      # Ensure /etc/hosts is reset on service stop
      preStop = ''
        ${cfg.package}/bin/focusd-merge-hosts || true
      '';
    };

    # Path watcher to trigger hosts merge when additions change
    systemd.paths.focusd-hosts-watcher = {
      description = "Watch for focusd hosts file changes";
      wantedBy = [ "multi-user.target" ];

      pathConfig = {
        PathModified = "/var/lib/focusd/hosts-additions";
        Unit = "focusd-merge-hosts.service";
      };
    };

    # Service triggered by path watcher to merge hosts
    systemd.services.focusd-merge-hosts = {
      description = "Merge focusd hosts additions into /etc/hosts";

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${cfg.package}/bin/focusd-merge-hosts";
        RemainAfterExit = false;
      };
    };

    # Path watcher for Firefox DoH exclusions
    systemd.paths.focusd-firefox-watcher = {
      description = "Watch for focusd Firefox exclusions changes";
      wantedBy = [ "multi-user.target" ];

      pathConfig = {
        PathModified = "/var/lib/focusd/firefox-excluded-domains";
        PathChanged = "/var/lib/focusd/firefox-excluded-domains";
        Unit = "focusd-update-firefox.service";
      };
    };

    # Service to update Firefox DoH configuration
    systemd.services.focusd-update-firefox = {
      description = "Update Firefox DoH exclusions from focusd";

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${cfg.package}/bin/focusd-update-firefox";
        RemainAfterExit = false;
      };
    };

    # Activation script to set up initial /etc/hosts
    system.activationScripts.focusd-setup = {
      text = ''
        # Ensure base hosts file exists and merge initially
        if [ ! -f /etc/hosts ]; then
          ${cfg.package}/bin/focusd-merge-hosts
        fi
      '';
      deps = [];
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
