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
      TIMELINE_LIMIT_HOURLY = 12;
      TIMELINE_LIMIT_DAILY = 7;
      TIMELINE_LIMIT_WEEKLY = 3;
      TIMELINE_LIMIT_MONTHLY = 1;
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

  # Monthly checksum verification of every btrfs filesystem (/, /nix).
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
  };

  environment.systemPackages = [ pkgs.btrfs-assistant ];
}
