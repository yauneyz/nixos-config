{ config, lib, pkgs, username ? "zac", ... }:

with lib;

let
  cfg = config.services.focuslock;
  stateFile = "/var/lib/focuslock/state.json";
  defaultStateFile = pkgs.writeText "focuslock-default-state.json" (builtins.toJSON {
    focusActive = false;
    focusSource = "boot";
    policy = {
      mode = "blacklist";
      domains = [ ];
      apps = [ ];
    };
    schedule = {
      windows = [ ];
    };
    pairedKeys = [ ];
  });
  importPolicy = pkgs.writeShellScript "focuslock-import-policy" ''
    set -eu

    state_file=${escapeShellArg stateFile}
    policy_file=${escapeShellArg cfg.policyFile}

    mkdir -p "$(dirname "$state_file")"

    if [ ! -s "$state_file" ]; then
      install -m 0644 ${escapeShellArg defaultStateFile} "$state_file"
    fi

    tmp="$(mktemp "$state_file.tmp.XXXXXX")"
    ${pkgs.jq}/bin/jq --slurpfile policy "$policy_file" '.policy = $policy[0]' "$state_file" > "$tmp"
    install -m 0644 "$tmp" "$state_file"
    rm -f "$tmp"
  '';
  exportPolicy = pkgs.writeShellScript "focuslock-export-policy" ''
    set -eu

    state_file=${escapeShellArg stateFile}
    policy_file=${escapeShellArg cfg.policyFile}
    policy_dir="$(dirname "$policy_file")"

    [ -s "$state_file" ] || exit 0

    install -d -m 0755 -o ${escapeShellArg username} -g users "$policy_dir"
    tmp="$(mktemp "$policy_dir/.focuslock-policy.json.XXXXXX")"
    ${pkgs.jq}/bin/jq '.policy' "$state_file" > "$tmp"
    install -m 0644 -o ${escapeShellArg username} -g users "$tmp" "$policy_file"
    rm -f "$tmp"
  '';
in {
  options.services.focuslock = {
    enable = mkEnableOption "FocusLock (snorlax) enforcement daemon";

    package = mkOption {
      type = types.package;
      default = pkgs.snorlax-daemon;
      defaultText = literalExpression "pkgs.snorlax-daemon";
      description = "The FocusLock daemon package (provides focuslock-svc and the svcctl/recover/natmsg CLIs).";
    };

    policyFile = mkOption {
      type = types.str;
      default = "/home/${username}/nixos-config/state/focuslock-policy.json";
      description = ''
        Version-controlled FocusLock policy file. The daemon imports this policy
        into /var/lib/focuslock/state.json at startup, and policy edits made
        through snorlax are exported back here by a systemd path watcher.
      '';
    };
  };

  config = mkIf cfg.enable {
    # The daemon enforces IP-level blocking via nftables.
    networking.nftables.enable = true;

    # Expose focuslock-svc/-svcctl/-recover/-natmsg system-wide (recovery, status, pairing).
    environment.systemPackages = [ cfg.package ];

    # Declarative replacement for `focuslock-svcctl install`. The svcctl installer would
    # otherwise write this unit imperatively and drop binaries under /opt; here we point
    # ExecStart at the Nix-store binary and let systemd own the runtime/state dirs.
    systemd.services.focuslock = {
      description = "FocusLock enforcement daemon";
      after = [ "network-online.target" "nftables.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      # focuslock-svc shells out to nft (IP blocking) and ip (routing) at runtime.
      # The policy sync hooks use jq/coreutils.
      path = with pkgs; [ nftables iproute2 jq coreutils ];

      serviceConfig = {
        Type = "simple";
        ExecStartPre = importPolicy;
        ExecStart = "${cfg.package}/bin/focuslock-svc";
        ExecStartPost = exportPolicy;
        Restart = "always";
        RestartSec = "1s";

        # Runs as unrestricted root (matching upstream's svcctl-generated unit). The
        # daemon needs broad privileges beyond networking: it writes paired-key files
        # to user-owned removable mounts (CAP_DAC_OVERRIDE — restricting caps here is
        # what caused "Could not write key file: Permission denied" on FAT/exFAT/NTFS
        # sticks), kills blocked processes owned by the user (CAP_KILL), and drives
        # nftables. Do not add a CapabilityBoundingSet without auditing all of these.
        User = "root";

        # RuntimeDirectory -> /run/focuslock (socket: /run/focuslock/focuslock.sock)
        RuntimeDirectory = "focuslock";
        RuntimeDirectoryMode = "0755";
        # StateDirectory -> /var/lib/focuslock (state.json, secure-store.json, recovery-code.txt)
        StateDirectory = "focuslock";
        StateDirectoryMode = "0750";
      };
    };

    systemd.services.focuslock-policy-sync = {
      description = "Sync FocusLock policy from daemon state into nixos-config";
      path = with pkgs; [ jq coreutils ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = exportPolicy;
      };
    };

    systemd.paths.focuslock-policy-sync = {
      description = "Watch FocusLock state for policy changes";
      wantedBy = [ "multi-user.target" ];
      pathConfig = {
        PathChanged = stateFile;
        Unit = "focuslock-policy-sync.service";
      };
    };
  };
}
