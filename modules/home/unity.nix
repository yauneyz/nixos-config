{
  lib,
  pkgs,
  userPaths,
  ...
}:
let
  editorVersion = "6000.0.66f2";
  editorChangeset = "b20bc5da3050";
  editorRoot = "${userPaths.dataHome}/Unity/Hub/Editor";
  unityHub = pkgs.unityhub;

  # Use the same Unity-specific FHS environment for Hub and direct editor runs.
  # It supplies Unity 6's native libraries, Git, Vulkan and graphics drivers.
  unityEditor = pkgs.writeShellScriptBin "unity-editor" ''
    set -euo pipefail
    unity_binary="''${UNITY_EDITOR_BINARY:-}"
    if [ -z "$unity_binary" ]; then
      for candidate in \
        ${lib.escapeShellArg "${editorRoot}/${editorVersion}/Editor/Unity"} \
        ${lib.escapeShellArg "${userPaths.home}/Unity/Hub/Editor/${editorVersion}/Editor/Unity"}; do
        if [ -x "$candidate" ]; then
          unity_binary="$candidate"
          break
        fi
      done
    fi
    if [ -z "$unity_binary" ] || [ ! -x "$unity_binary" ]; then
      echo "Unity ${editorVersion} is not installed. Run unity-install-editor, then sign in and activate your license in unityhub." >&2
      echo "For a custom install, set UNITY_EDITOR_BINARY to the real Editor/Unity executable." >&2
      exit 2
    fi
    exec ${unityHub.fhsEnv}/bin/unityhub-fhs-env "$unity_binary" -force-vulkan "$@"
  '';

  # Keep large, version-pinned editor downloads on the data partition.
  # Downloads are explicit, never a side effect of Home Manager activation.
  unityInstallEditor = pkgs.writeShellScriptBin "unity-install-editor" ''
    set -euo pipefail
    if [ -x ${lib.escapeShellArg "${editorRoot}/${editorVersion}/Editor/Unity"} ]; then
      echo "Unity ${editorVersion} is already installed at ${editorRoot}."
      exit 0
    fi
    ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg editorRoot}
    ${unityHub}/bin/unityhub --headless install-path --set ${lib.escapeShellArg editorRoot}
    exec ${unityHub}/bin/unityhub --headless install \
      --version ${editorVersion} --changeset ${editorChangeset} "$@"
  '';
in
{
  home.packages = [
    unityHub
    unityEditor
    unityInstallEditor
  ];

  home.sessionVariables.UNITY_EDITOR = "${unityEditor}/bin/unity-editor";
}
