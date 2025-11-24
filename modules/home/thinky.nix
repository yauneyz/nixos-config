{ config, ... }:
let
  homeDir = config.home.homeDirectory;
in
{
  # Keep Thinky's runtime state file pointed at the repo copy
  home.file.".config/Thinky/app-state.edn".source =
    config.lib.file.mkOutOfStoreSymlink "${homeDir}/development/org/thinky/app-state.edn";
}
