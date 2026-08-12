{
  config,
  host,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.zac.desktop.shell;
  colors = config.lib.stylix.colors.withHashtag;
  preferredWorkspaces =
    if host == "desktop" then
      {
        "DP-1" = [
          8
          9
          10
        ];
        "DP-2" = [
          1
          2
          3
          4
          5
          6
          7
          11
          12
          13
          14
          15
        ];
      }
    else
      {
        "*" = [
          1
          2
          3
          4
          5
        ];
      };

  shellConfig = pkgs.runCommandLocal "zac-quickshell-config" { } ''
    cp -R ${./config} "$out"
    chmod -R u+w "$out"
    substituteInPlace "$out/Theme.qml" \
      --replace-fail "@BASE00@" "${colors.base00}" \
      --replace-fail "@BASE01@" "${colors.base01}" \
      --replace-fail "@BASE02@" "${colors.base02}" \
      --replace-fail "@BASE03@" "${colors.base03}" \
      --replace-fail "@BASE04@" "${colors.base04}" \
      --replace-fail "@BASE05@" "${colors.base05}" \
      --replace-fail "@BASE08@" "${colors.base08}" \
      --replace-fail "@BASE0A@" "${colors.base0A}" \
      --replace-fail "@BASE0B@" "${colors.base0B}" \
      --replace-fail "@BASE0C@" "${colors.base0C}" \
      --replace-fail "@BASE0D@" "${colors.base0D}" \
      --replace-fail "@BASE0E@" "${colors.base0E}"
    substituteInPlace "$out/RuntimeConfig.qml" \
      --replace-fail "@REDUCED_MOTION@" "${lib.boolToString cfg.reducedMotion}" \
      --replace-fail "@PERFORMANCE_MODE@" "${lib.boolToString cfg.performanceMode}" \
      --replace-fail "@PREFERRED_WORKSPACES@" '${builtins.toJSON preferredWorkspaces}'
  '';

  shellctl = pkgs.writeShellApplication {
    name = "zac-shell";
    runtimeInputs = [ pkgs.quickshell ];
    text = ''
      if (( $# < 1 )); then
        echo "usage: zac-shell {toggle|open|close|notifications|osd|audio|mic|brightness|reload} [arguments...]" >&2
        exit 2
      fi

      command=$1
      shift
      case "$command" in
        toggle) qs --config zac-shell ipc call shell togglePanel "$@" ;;
        open) qs --config zac-shell ipc call shell openPanel "$@" ;;
        close) qs --config zac-shell ipc call shell closePanel ;;
        notifications) qs --config zac-shell ipc call shell toggleNotificationCenter ;;
        osd) qs --config zac-shell ipc call shell showOsd "$@" ;;
        audio) qs --config zac-shell ipc call shell changeAudio "$@" ;;
        mic) qs --config zac-shell ipc call shell changeMic "$@" ;;
        brightness) qs --config zac-shell ipc call shell changeBrightness "$@" ;;
        reload) qs --config zac-shell ipc call shell reload ;;
        *) echo "zac-shell: unknown command: $command" >&2; exit 2 ;;
      esac
    '';
  };

  diagnostics = pkgs.writeShellApplication {
    name = "zac-shell-diagnostics";
    runtimeInputs = with pkgs; [
      bluez
      coreutils
      gnugrep
      hyprland
      jq
      networkmanager
      procps
      quickshell
      systemd
      wireplumber
    ];
    text = ''
      echo "backend: ${cfg.backend}"
      echo "quickshell: $(qs --version 2>&1 | head -n1)"
      systemctl --user --no-pager --full status zac-quickshell.service || true
      echo
      qs --config zac-shell list || true
      echo
      echo "monitors:"
      hyprctl -j monitors 2>/dev/null | jq -r '.[] | "  \(.name): \(.width)x\(.height) scale=\(.scale) workspace=\(.activeWorkspace.id)"' || true
      echo "pipewire:"
      wpctl status 2>/dev/null | sed -n '/Audio/,/Video/p' | head -n 24 || true
      echo "bluetooth:"
      bluetoothctl show 2>/dev/null | grep -E '^\s*(Name|Powered|Discovering):' || true
      bluetoothctl devices Connected 2>/dev/null || true
      echo "network:"
      nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null || true
    '';
  };
in
{
  imports = [
    ./keybinds.nix
    ./service.nix
  ];

  options.zac.desktop.shell = {
    backend = lib.mkOption {
      type = lib.types.enum [
        "legacy"
        "quickshell"
      ];
      default = "legacy";
      description = "Runtime owner for the bar, notifications, and OSD.";
    };

    reducedMotion = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Reduce non-essential Quickshell motion.";
    };

    performanceMode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Disable ambient effects and expensive polling.";
    };
  };

  config = {
    home.packages = [
      diagnostics
      pkgs.quickshell
      pkgs.qt6.qtmultimedia
      shellctl
    ];

    xdg.configFile."quickshell/zac-shell" = {
      source = shellConfig;
      recursive = true;
    };

  };
}
