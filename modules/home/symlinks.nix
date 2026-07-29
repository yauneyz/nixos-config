{
  config,
  lib,
  userPaths,
  ...
}:
let
  inherit (userPaths)
    dataHome
    development
    home
    org
    ;
  mkDataLink = target: {
    source = config.lib.file.mkOutOfStoreSymlink "${dataHome}/${target}";
  };

  dataHomeLinks = {
    "Documents" = mkDataLink "Documents";
    "Downloads" = mkDataLink "Downloads";
    "development" = mkDataLink "development";
    "Music" = mkDataLink "Music";
    "Pictures" = mkDataLink "Pictures";
    "Videos" = mkDataLink "Videos";
    "Desktop" = mkDataLink "Desktop";
    "Writing" = mkDataLink "Writing";
    "org" = mkDataLink "org";
    "Sheet Music" = mkDataLink "Sheet Music";
    "Main" = mkDataLink "Main";
    "dotfiles" = mkDataLink "dotfiles";
    ".tools" = mkDataLink "dotfiles/.tools";
    "Games/Retroid" = mkDataLink "Games/Retroid";
    "Games/Wii-U" = mkDataLink "Games/Wii-U";
  };
in
{
  # Home directory symlinks
  # Using mkOutOfStoreSymlink to create direct symlinks instead of copying to Nix store

  home.file = lib.optionalAttrs (dataHome != home) dataHomeLinks // {
    # Thinky app-state.edn is host-shared through the personal org tree.
    ".config/Thinky/app-state.edn".source =
      config.lib.file.mkOutOfStoreSymlink "${org}/thinky/app-state.edn";

    # Stable, host-agnostic leaf symlink to the snorlax checkout, consumed by the
    # `snorlax` flake input in flake.nix. Direct child of the (real) home dir, so
    # nix's git fetcher accepts it on desktop too — where ~/development itself is a
    # symlink and thus rejected as a parent path component. Points at the data
    # partition on desktop, the real home tree on the laptop.
    ".snorlax-src".source =
      config.lib.file.mkOutOfStoreSymlink "${development}/snorlax";
  };
}
