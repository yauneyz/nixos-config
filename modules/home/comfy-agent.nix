{
  host,
  lib,
  pkgs,
  userPaths,
  ...
}:
# Lets Claude Code drive ComfyUI through comfyui-mcp. Starting `claude` in
# ~/development/comfy loads the server and pre-approves its tools.
#
# desktop: talks to the local ComfyUI service (systemctl --user start comfyui)
#          and gets direct access to its models/state/output directories.
# laptop:  talks to the desktop's ComfyUI through the `comfy-remote` SSH
#          tunnel on 127.0.0.1:18188; run `comfy-remote` before `claude`.
let
  projectDir = "development/comfy";

  # Must match modules/home/video-ai on the desktop.
  videoAi = "${userPaths.home}/Games/VideoAI";
  models = "${userPaths.models}/VideoAI";

  hostSettings = {
    desktop = {
      env = {
        COMFYUI_URL = "http://127.0.0.1:8188";
        COMFYUI_PATH = "${videoAi}/state/comfyui";
      };
      directories = [
        "${videoAi}/state/comfyui"
        "${videoAi}/exports/comfyui"
        "${videoAi}/work/comfyui"
        "${models}/comfy"
      ];
    };
    laptop = {
      env = {
        COMFYUI_URL = "http://127.0.0.1:18188";
        # Loopback here is a tunnel to the desktop: don't hunt for a local
        # install, move files over the ComfyUI HTTP API instead.
        COMFYUI_MCP_FORCE_REMOTE = "1";
      };
      directories = [ ];
    };
  };
  cfg = hostSettings.${host} or null;

  mcpConfig = {
    mcpServers.comfyui = {
      command = lib.getExe pkgs.comfyui-mcp;
      args = [ "--full" ];
      inherit (cfg) env;
    };
  };

  claudeSettings = {
    enableAllProjectMcpServers = true;
    permissions = {
      allow = [
        "mcp__comfyui__*"
        "Bash(curl -s ${cfg.env.COMFYUI_URL}/*)"
      ];
      # ComfyUI core and its venv are Nix-managed by `video-ai apps`; the
      # server's install/restart paths assume a conventional install.
      deny = [
        "mcp__comfyui__install_comfyui"
        "mcp__comfyui__restart_comfyui"
      ];
      additionalDirectories = cfg.directories;
    };
  };
  mcpJson = pkgs.writeText "comfy-agent-mcp.json" (builtins.toJSON mcpConfig);
  settingsJson = pkgs.writeText "comfy-agent-settings.json" (builtins.toJSON claudeSettings);
in
lib.mkIf (cfg != null) {
  home = {
    packages = [ pkgs.comfyui-mcp ];
    # Not home.file: on the desktop ~/development is a symlink into /data, and
    # home-manager refuses to install files whose real path is outside $HOME.
    # Rewritten on every activation, so hand edits are reverted; per-user
    # tweaks belong in .claude/settings.local.json.
    activation.comfyAgentProject = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      dir=${lib.escapeShellArg "${userPaths.home}/${projectDir}"}
      run ${pkgs.coreutils}/bin/mkdir -p "$dir/.claude"
      run ${pkgs.coreutils}/bin/install -m 644 ${mcpJson} "$dir/.mcp.json"
      run ${pkgs.coreutils}/bin/install -m 644 ${settingsJson} "$dir/.claude/settings.json"
    '';
  };
}
