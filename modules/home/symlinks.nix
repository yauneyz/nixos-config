{
  config,
  lib,
  userPaths,
  ...
}:
let
  inherit (userPaths)
    dataHome
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
  };
}
