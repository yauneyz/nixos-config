{
  lib,
  pkgs,
  host,
  username,
  userPaths,
  ...
}:
let
  enabled = host == "desktop";
  mountPoint = "/run/media/${username}/Kindle";
  source = "${userPaths.dataHome}/Main/Books/";
  # Deliberately outside documents/ and dot-prefixed: the native Kindle
  # library scanner (com.lab126.scanner) watches the whole /mnt/us/ tree, not
  # just documents/, so anything under documents/ gets picked up as a
  # "downloaded" book in the stock Library. Dot-prefixed top-level folders
  # are skipped — the jailbreak framework itself hides here
  # (.active_content_sandbox) — which keeps KOReader's library invisible to
  # the native app entirely. Verified on-device 2026-08-19.
  dest = "${mountPoint}/.books/";
in
{
  # Opportunistic one-way mirror of ~/Main/Books onto the Kindle's document
  # folder. Fires only when the Kindle is already mounted via USB mass
  # storage (no forced Wi-Fi, no background polling) — see conversation
  # 2026-08-19. --update (not --delete): a local deletion should never
  # remove a book from the device; this is a push mirror, not a two-way sync.
  systemd.user.services.kindle-sync = lib.mkIf enabled {
    Unit = {
      Description = "Mirror ~/Main/Books onto a connected Kindle, hidden from the native Library";
    };
    Service = {
      Type = "oneshot";
      # Recurse into subfolders but only transfer pdf/epub files — everything
      # else (app caches, other formats) is dropped by the final exclude.
      ExecStart = "${pkgs.rsync}/bin/rsync -a --update --mkpath --include='*/' --include='*.pdf' --include='*.epub' --exclude='*' ${source} ${dest}";
    };
  };

  systemd.user.paths.kindle-sync = lib.mkIf enabled {
    Unit = {
      Description = "Watch for the Kindle being mounted via USB";
    };
    Path = {
      # PathExists is level-triggered: for a mountpoint that stays present,
      # systemd re-evaluates it after every oneshot completion and refires
      # immediately in a loop (documented systemd.path(5) behavior — hit this
      # live 2026-08-19, three back-to-back re-triggers on an unchanged
      # mount). PathChanged is edge-triggered on the actual mount/unmount
      # event, so it fires once per connection instead.
      PathChanged = mountPoint;
    };
    Install.WantedBy = [ "paths.target" ];
  };
}
