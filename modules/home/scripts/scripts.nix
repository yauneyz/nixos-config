{
  host,
  lib,
  pkgs,
  ...
}:
let
  scriptDir = ./scripts;
  scriptEntries = builtins.readDir scriptDir;

  regularFiles = builtins.filter (name: scriptEntries.${name} == "regular") (
    builtins.attrNames scriptEntries
  );

  shellScripts = builtins.filter (name: builtins.match ".*\\.sh$" name != null) regularFiles;

  mkScript = name: {
    inherit name;
    value = pkgs.writeScriptBin (builtins.replaceStrings [ ".sh" ] [ "" ] name) (
      builtins.readFile (scriptDir + "/${name}")
    );
  };

  scriptsSet = builtins.listToAttrs (map mkScript shellScripts);
  scripts = builtins.attrValues scriptsSet;
  rebuildScript = pkgs.writeScriptBin "rebuild" (builtins.readFile ../../../scripts/rebuild.sh);
  llmServeSource = pkgs.writeText "llm-serve.py" (builtins.readFile ./scripts/llm-serve.py);
  llmServe = pkgs.writeShellApplication {
    name = "llm-serve";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      exec python3 ${llmServeSource} "$@"
    '';
  };
  comfyRemote = pkgs.writeShellApplication {
    name = "comfy-remote";
    runtimeInputs = with pkgs; [
      curl
      openssh
      util-linux
      xdg-utils
    ];
    text = ''
      socket="''${XDG_RUNTIME_DIR:?Run this from your laptop user session}/comfy-remote.sock"
      url=http://127.0.0.1:18188

      case "''${1:-}" in
        --close) exec ssh -S "$socket" -O exit desktop ;;
        "") ;;
        *) printf 'Usage: comfy-remote [--close]\n' >&2; exit 2 ;;
      esac

      (
        flock 9
        ssh -o ClearAllForwardings=yes desktop systemctl --user start comfyui.service
        if ! ssh -S "$socket" -O check desktop 2>/dev/null; then
          rm -f -- "$socket"
          ssh -fNM -S "$socket" -o ControlPersist=no -o ExitOnForwardFailure=yes \
            -o ServerAliveInterval=15 -L 127.0.0.1:18188:127.0.0.1:8188 desktop 9>&-
        fi
      ) 9>"$socket.lock"

      for _ in {1..20}; do
        if curl --noproxy '*' --silent --fail --max-time 1 "$url/system_stats" >/dev/null; then
          printf 'ComfyUI on desktop: %s\n' "$url"
          exec xdg-open "$url"
        fi
        sleep 1
      done
      printf 'ComfyUI did not answer at %s. Check ssh desktop journalctl --user -u comfyui.\n' "$url" >&2
      exit 1
    '';
  };
in
{
  home.packages =
    scripts
    ++ [
      rebuildScript
      llmServe
    ]
    ++ lib.optionals (host == "desktop") [ pkgs.ddcutil ]
    ++ lib.optionals (host == "laptop") [ comfyRemote ];

  xdg.configFile."llm-serve/config.toml".source = ./llm-serve.toml;
  xdg.desktopEntries.comfy-remote = lib.mkIf (host == "laptop") {
    name = "ComfyUI (Desktop GPU)";
    exec = "${comfyRemote}/bin/comfy-remote";
    terminal = true;
    icon = "applications-graphics";
    categories = [ "Graphics" ];
  };
}
