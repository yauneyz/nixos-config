{ config, lib, pkgs, username ? "zac", ... }:

with lib;

let
  cfg = config.services.talysman;
  stateFile = "/var/lib/talysman/state.json";
  defaultStateFile = pkgs.writeText "talysman-default-state.json" (builtins.toJSON {
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
    settings = {
      browserHandshakeEnabled = false;
    };
    pairedKeys = [ ];
  });
  importPolicy = pkgs.writeShellScript "talysman-import-policy" ''
    set -eu

    state_file=${escapeShellArg stateFile}
    policy_file=${escapeShellArg cfg.policyFile}
    state_dir="$(dirname "$state_file")"
    legacy_state_dir=/var/lib/focuslock

    mkdir -p "$state_dir"

    # One-time migration from the pre-rename state directory.
    for name in state.json secure-store.json recovery-code.txt; do
      if [ -e "$legacy_state_dir/$name" ] && [ ! -e "$state_dir/$name" ]; then
        cp -a "$legacy_state_dir/$name" "$state_dir/$name"
      fi
    done

    if [ ! -s "$state_file" ]; then
      install -m 0644 ${escapeShellArg defaultStateFile} "$state_file"
    fi

    tmp="$(mktemp "$state_file.tmp.XXXXXX")"
    ${pkgs.jq}/bin/jq --slurpfile policy "$policy_file" '.policy = $policy[0]' "$state_file" > "$tmp"
    install -m 0644 "$tmp" "$state_file"
    rm -f "$tmp"
  '';
  exportPolicy = pkgs.writeShellScript "talysman-export-policy" ''
    set -eu

    state_file=${escapeShellArg stateFile}
    policy_file=${escapeShellArg cfg.policyFile}
    policy_dir="$(dirname "$policy_file")"

    [ -s "$state_file" ] || exit 0

    install -d -m 0755 -o ${escapeShellArg username} -g users "$policy_dir"
    tmp="$(mktemp "$policy_dir/.talysman-policy.json.XXXXXX")"
    ${pkgs.jq}/bin/jq '.policy' "$state_file" > "$tmp"
    install -m 0644 -o ${escapeShellArg username} -g users "$tmp" "$policy_file"
    rm -f "$tmp"
  '';
in {
  options.services.talysman = {
    enable = mkEnableOption "Talysman enforcement daemon";

    package = mkOption {
      type = types.package;
      default = pkgs.talysman-daemon;
      defaultText = literalExpression "pkgs.talysman-daemon";
      description = "The Talysman daemon package (provides talysman-svc and the svcctl/recover/natmsg CLIs).";
    };

    policyFile = mkOption {
      type = types.str;
      default = "/home/${username}/nixos-config/state/talysman-policy.json";
      description = ''
        Version-controlled Talysman policy file. The daemon imports this policy
        into /var/lib/talysman/state.json at startup, and policy edits made
        through snorlax are exported back here by a systemd path watcher.
      '';
    };
  };

  config = mkIf cfg.enable {
    # The daemon enforces IP-level blocking via nftables.
    networking.nftables.enable = true;

    # Expose talysman-svc/-svcctl/-recover/-natmsg system-wide (recovery, status, pairing).
    environment.systemPackages = [ cfg.package ];

    # Declarative replacement for `talysman-svcctl install`. The svcctl installer would
    # otherwise write this unit imperatively and drop binaries under /opt; here we point
    # ExecStart at the Nix-store binary and let systemd own the runtime/state dirs.
    systemd.services.talysman = {
      description = "Talysman enforcement daemon";
      after = [ "network-online.target" "nftables.service" ];
      conflicts = [ "focuslock.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      # talysman-svc shells out to nft (IP blocking) and ip (routing) at runtime.
      # The policy sync hooks use jq/coreutils.
      path = with pkgs; [ nftables iproute2 jq coreutils ];

      serviceConfig = {
        Type = "simple";
        ExecStartPre = importPolicy;
        ExecStart = "${cfg.package}/bin/talysman-svc";
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

        # RuntimeDirectory -> /run/talysman (socket: /run/talysman/talysman.sock)
        RuntimeDirectory = "talysman";
        RuntimeDirectoryMode = "0755";
        # StateDirectory -> /var/lib/talysman (state.json, secure-store.json, recovery-code.txt)
        StateDirectory = "talysman";
        StateDirectoryMode = "0750";
      };
    };

    systemd.services.talysman-policy-sync = {
      description = "Sync Talysman policy from daemon state into nixos-config";
      path = with pkgs; [ jq coreutils ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = exportPolicy;
      };
    };

    systemd.paths.talysman-policy-sync = {
      description = "Watch Talysman state for policy changes";
      wantedBy = [ "multi-user.target" ];
      pathConfig = {
        PathChanged = stateFile;
        Unit = "talysman-policy-sync.service";
      };
    };
  };
}
