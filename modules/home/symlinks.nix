{ config, ... }:
let
  homeDir = config.home.homeDirectory;
in
{
  # Home directory symlinks
  # Using mkOutOfStoreSymlink to create direct symlinks instead of copying to Nix store

  # Symlink directories from /data to home folder
  home.file."Documents".source = config.lib.file.mkOutOfStoreSymlink "/data/zac/zac/Documents";
  home.file."Downloads".source = config.lib.file.mkOutOfStoreSymlink "/data/zac/zac/Downloads";
  home.file."development".source = config.lib.file.mkOutOfStoreSymlink "/data/zac/zac/development";
  home.file."Music".source = config.lib.file.mkOutOfStoreSymlink "/data/zac/zac/Music";
  home.file."Pictures".source = config.lib.file.mkOutOfStoreSymlink "/data/zac/zac/Pictures";
  home.file."Videos".source = config.lib.file.mkOutOfStoreSymlink "/data/zac/zac/Videos";
  home.file."Desktop".source = config.lib.file.mkOutOfStoreSymlink "/data/zac/zac/Desktop";
  home.file."Writing".source = config.lib.file.mkOutOfStoreSymlink "/data/zac/zac/Writing";
  home.file."org".source = config.lib.file.mkOutOfStoreSymlink "/data/zac/zac/org";
  home.file."Sheet Music".source = config.lib.file.mkOutOfStoreSymlink "/data/zac/zac/Sheet Music";
  home.file."Main".source = config.lib.file.mkOutOfStoreSymlink "/data/zac/zac/Main";
  home.file."dotfiles".source = config.lib.file.mkOutOfStoreSymlink "/data/zac/zac/dotfiles";
  home.file.".tools".source = config.lib.file.mkOutOfStoreSymlink "/home/zac/dotfiles/.tools";
  home.file."Games/Retroid".source = config.lib.file.mkOutOfStoreSymlink "/data/zac/zac/Games/Retroid";
  home.file."Games/Wii-U".source = config.lib.file.mkOutOfStoreSymlink "/data/zac/zac/Games/Wii-U";

  # Thinky app-state.edn symlink
  # Real file lives in ~/development/org/thinky/app-state.edn
  # Symlink from ~/.config/Thinky/app-state.edn points to it
  home.file.".config/Thinky/app-state.edn".source =
    config.lib.file.mkOutOfStoreSymlink "${homeDir}/development/org/thinky/app-state.edn";
}
