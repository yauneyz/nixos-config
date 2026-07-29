# Desktop-only: the big personal-data trees live on the /data partition and are
# bind-mounted into the login home so `~/development`, `~/Documents`, etc. are real
# directories (not symlinks). Replaces the old home-manager symlink farm
# (modules/home/symlinks.nix). The laptop has no /data partition and skips all of
# this — its home is entirely native.
#
# Each entry mounts  ~/<target>  <-  <dataHome>/<source>.  `depends = [ "/data" ]`
# ensures the source partition is mounted first. Sources must exist or the mount
# fails at boot.
{
  config,
  lib,
  ...
}:
let
  inherit (config.zac.paths) home dataHome;

  # target (under ~)      = source (under dataHome, i.e. /data/zac)
  binds = {
    "Documents" = "Documents";
    "Downloads" = "Downloads";
    "development" = "development";
    "Music" = "Music";
    "Pictures" = "Pictures";
    "Videos" = "Videos";
    "Desktop" = "Desktop";
    "Writing" = "Writing";
    "Main" = "Main";
    "Sheet Music" = "Sheet Music";
    "dotfiles" = "dotfiles";
    "org" = "development/org"; # the real org tree (matches zac.paths.org)
    ".tools" = "dotfiles/.tools";
    "Android" = "Android";
    ".android" = ".android";
    "Games/Retroid" = "Games/Retroid";
    "Games/Wii-U" = "Games/Wii-U";
  };
in
{
  fileSystems = lib.mapAttrs' (
    target: source:
    lib.nameValuePair "${home}/${target}" {
      device = "${dataHome}/${source}";
      options = [ "bind" ];
      depends = [ "/data" ];
    }
  ) binds;
}
