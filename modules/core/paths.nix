{
  config,
  lib,
  host,
  username,
  ...
}:
let
  accountHome = "/home/${username}";
  defaultDataHome = if host == "desktop" then "/data/${username}/${username}" else accountHome;
  cfg = config.zac.paths;
in
{
  options.zac.paths = {
    home = lib.mkOption {
      type = lib.types.str;
      default = accountHome;
      description = "The real login home directory for the primary user.";
    };

    dataHome = lib.mkOption {
      type = lib.types.str;
      default = defaultDataHome;
      description = "Root for personal data. On desktop this points at the data partition.";
    };

    development = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.dataHome}/development";
      description = "Personal development tree.";
    };

    org = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.development}/org";
      description = "Org files tree.";
    };

    dotfiles = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.dataHome}/dotfiles";
      description = "Personal dotfiles tree.";
    };

    models = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.dataHome}/Games/Models";
      description = "Local ML model storage.";
    };

    nixosConfig = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.home}/nixos-config";
      description = "This NixOS flake checkout.";
    };
  };
}
