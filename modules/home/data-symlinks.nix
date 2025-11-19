{ config, ... }:
{
  # Symlink directories from /data to home folder
  # Using mkOutOfStoreSymlink to create direct symlinks instead of copying to Nix store

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
}
