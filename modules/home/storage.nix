{
  lib,
  pkgs,
  userPaths,
  ...
}:
let
  inherit (userPaths) dataHome home;
  cacheHome = "${dataHome}/.cache";
  localShare = "${dataHome}/.local/share";
  npmPrefix = "${dataHome}/.npm-global";
  localBin = "${dataHome}/.local/bin";
  steamLocal = "${home}/Games/SteamLocal";
in
{
  home.sessionVariables = lib.mkIf (dataHome != home) {
    XDG_CACHE_HOME = cacheHome;

    ANDROID_HOME = "${dataHome}/Android/Sdk";
    ANDROID_SDK_ROOT = "${dataHome}/Android/Sdk";
    ANDROID_USER_HOME = "${dataHome}/.android";
    ANDROID_AVD_HOME = "${dataHome}/.android/avd";

    CUDA_CACHE_PATH = "${cacheHome}/cuda";
    ML_UV_ENV_DIR = "${localShare}/nixos-ml";
    UV_CACHE_DIR = "${cacheHome}/uv";
    PIP_CACHE_DIR = "${cacheHome}/pip";
    PIPX_HOME = "${localShare}/pipx";
    PIPX_BIN_DIR = localBin;

    NPM_CONFIG_CACHE = "${cacheHome}/npm";
    NPM_CONFIG_PREFIX = npmPrefix;
    PNPM_HOME = "${localShare}/pnpm";
    NPM_CONFIG_STORE_DIR = "${localShare}/pnpm/store";
  };

  home.sessionPath = lib.mkIf (dataHome != home) [
    localBin
    "${npmPrefix}/bin"
    "${localShare}/pnpm"
  ];

  home.activation.moveRootCachesToData = lib.mkIf (dataHome != home) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      timestamp="$(${pkgs.coreutils}/bin/date +%Y%m%d%H%M%S)"

      migrate_path() {
        src="$1"
        dst="$2"

        if [ -L "$src" ]; then
          return
        fi

        ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$dst")"

        if [ ! -e "$src" ]; then
          if [ ! -e "$dst" ]; then
            ${pkgs.coreutils}/bin/mkdir -p "$dst"
          fi
          ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$src")"
          ${pkgs.coreutils}/bin/ln -s "$dst" "$src"
          return
        fi

        if [ -e "$dst" ] || [ -L "$dst" ]; then
          backup="$dst.pre-root-migration-$timestamp"
          suffix=0
          while [ -e "$backup" ] || [ -L "$backup" ]; do
            suffix=$((suffix + 1))
            backup="$dst.pre-root-migration-$timestamp-$suffix"
          done
          ${pkgs.coreutils}/bin/mv "$dst" "$backup"
        fi

        ${pkgs.coreutils}/bin/mv "$src" "$dst"
        ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$src")"
        ${pkgs.coreutils}/bin/ln -s "$dst" "$src"
      }

      migrate_path "${home}/.cache/uv" "${cacheHome}/uv"
      migrate_path "${home}/.cache/pip" "${cacheHome}/pip"
      migrate_path "${home}/.cache/pnpm" "${cacheHome}/pnpm"
      migrate_path "${home}/.cache/npm" "${cacheHome}/npm"
      migrate_path "${home}/.cache/spotify" "${cacheHome}/spotify"
      migrate_path "${home}/.cache/huggingface" "${cacheHome}/huggingface"

      migrate_path "${home}/.npm" "${dataHome}/.npm"
      migrate_path "${home}/.npm-global" "${npmPrefix}"
      migrate_path "${home}/.local/share/pnpm" "${localShare}/pnpm"
      migrate_path "${home}/.local/share/nixos-ml" "${localShare}/nixos-ml"
      migrate_path "${home}/.local/share/vicinae" "${localShare}/vicinae"
      migrate_path "${home}/.local/share/Trash" "${localShare}/Trash"

      migrate_path "${home}/Android" "${dataHome}/Android"
      migrate_path "${home}/.android" "${dataHome}/.android"

      migrate_path "${home}/.local/share/Steam/steamapps/common" "${steamLocal}/steamapps/common"
      migrate_path "${home}/.local/share/Steam/steamapps/compatdata" "${steamLocal}/steamapps/compatdata"
      migrate_path "${home}/.local/share/Steam/steamapps/shadercache" "${steamLocal}/steamapps/shadercache"
      migrate_path "${home}/.local/share/Steam/steamapps/workshop" "${steamLocal}/steamapps/workshop"
      migrate_path "${home}/.local/share/Steam/userdata" "${steamLocal}/userdata"
    ''
  );
}
