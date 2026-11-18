{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  rootIsBtrfs = (config.fileSystems."/".fsType or "") == "btrfs";
in
lib.mkIf rootIsBtrfs {
  # Timeline snapshots of / (which is the top-level btrfs subvolume on both
  # desktop and laptop, so it includes /home). Nested subvolumes -- /tmp,
  # /var/tmp, /.snapshots itself -- are excluded automatically, and /nix lives
  # on its own filesystem on the desktop.
  #
  # These are local undo points, not off-machine backups.
  #   snapper list                         # what snapshots exist
  #   snapper status 41..0                 # what changed since snapshot 41
  #   snapper undochange 41..0 <path>      # put files back as they were
  #   ls /.snapshots/41/snapshot/home/zac  # or just copy things out
  # btrfs-assistant is a GUI for browsing/diffing/restoring.
  services.snapper = {
    snapshotInterval = "hourly";
    cleanupInterval = "1h";
    persistentTimer = true;

    configs.root = {
      SUBVOLUME = "/";
      ALLOW_USERS = [ username ];
      SYNC_ACL = true;

      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
      TIMELINE_MIN_AGE = 1800;
      # A fixed count is also the minimum: FREE_LIMIT cannot prune below it.
      # Keep the usual history while allowing pressure cleanup down to one
      # recent undo point. Free-space cleanup does not require btrfs quotas.
      TIMELINE_LIMIT_HOURLY = "1-12";
      TIMELINE_LIMIT_DAILY = "0-7";
      TIMELINE_LIMIT_WEEKLY = "0-3";
      TIMELINE_LIMIT_MONTHLY = "0-1";
      TIMELINE_LIMIT_QUARTERLY = 0;
      TIMELINE_LIMIT_YEARLY = 0;

      # The desktop root partition is only ~78G. Snapshots pin deleted data,
      # so let cleanup thin them out early if free space drops below 20%.
      FREE_LIMIT = "0.2";
    };
  };

  # snapper needs /.snapshots to be a subvolume; tmpfiles' `v` creates one on
  # btrfs if it is missing (fresh installs / the laptop).
  systemd.tmpfiles.rules = [ "v /.snapshots 0750 root root -" ];

  # Bound live logs and crash dumps; snapshots can retain older copies until
  # they expire. Manual snapshots without a cleanup algorithm never expire.
  services.journald.settings.Journal = {
    SystemMaxUse = "512M";
    SystemKeepFree = "4G";
    MaxRetentionSec = "14day";
  };
  systemd.coredump.settings.Coredump = {
    MaxUse = "512M";
    KeepFree = "4G";
  };

  # Deleted snapshot data can leave free space trapped in allocated data
  # chunks. Keep workspace for metadata growth without a full balance.
  systemd.services.btrfs-root-workspace = {
    description = "Maintain Btrfs root metadata allocation workspace";
    after = [ "snapper-cleanup.service" ];
    unitConfig.OnFailure = "btrfs-root-space-alert.service";
    path = [ pkgs.btrfs-progs pkgs.gawk ];
    serviceConfig = {
      Type = "oneshot";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
    script = ''
      read_unallocated() {
        unallocated=$(LC_ALL=C btrfs filesystem usage -b / |
          awk '$1 == "Device" && $2 == "unallocated:" { print $3 }')
        if [[ ! "$unallocated" =~ ^[0-9]+$ ]]; then
          echo "Could not read Btrfs unallocated space" >&2
          exit 1
        fi
      }
      read_unallocated
      if (( unallocated < 8 * 1024 * 1024 * 1024 )); then
        btrfs balance start -dusage=0 /
        btrfs balance start -dusage=50,limit=8 /
        read_unallocated
        if (( unallocated < 4 * 1024 * 1024 * 1024 )); then
          btrfs balance start -dusage=75,limit=8 /
          read_unallocated
        fi
      fi
      echo "Btrfs root unallocated workspace: $unallocated bytes"
      if (( unallocated < 4 * 1024 * 1024 * 1024 )); then
        echo "Btrfs root workspace below 4 GiB; free live data or expired snapshots" >&2
        exit 1
      fi
    '';
  };
  systemd.timers.btrfs-root-workspace = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "15m";
    };
  };
  systemd.services.btrfs-root-space-alert = {
    description = "Warn about insufficient Btrfs metadata workspace";
    serviceConfig.Type = "oneshot";
    path = [ pkgs.coreutils pkgs.util-linux pkgs.libnotify ];
    script = ''
      message="Btrfs root allocation workspace could not be restored. Check: journalctl -u btrfs-root-workspace. Free live data or expired snapshots before the disk fills."
      echo "$message" | wall
      uid=$(id -u ${lib.escapeShellArg username})
      if [ -S "/run/user/$uid/bus" ]; then
        runuser -u ${lib.escapeShellArg username} -- env \
          DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
          notify-send -u critical "Btrfs disk space needs attention" "$message"
      fi
    '';
  };

  # Monthly checksum verification of every btrfs filesystem (/, /nix).
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
  };

  environment.systemPackages = [ pkgs.btrfs-assistant ];
}
