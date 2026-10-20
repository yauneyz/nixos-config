{ config, pkgs, ... }:
let
  # Moves the desktop onto a virtual monitor sized for the Moonlight client
  # while a stream runs, and switches the physical monitors off so they go
  # into ordinary no-signal standby (fully black, wake normally afterwards).
  sunshineDisplay = pkgs.writeShellApplication {
    name = "sunshine-display";
    runtimeInputs = [
      config.programs.hyprland.package
      pkgs.jq
      pkgs.systemd
    ];
    text = ''
      virtual=sunshine
      # Client mode of the running Sunshine session. Present from the session's
      # prep command until it is quit, so reconnects can restore the mode.
      session_file="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/sunshine-display-session"

      start() {
        if [[ -n "''${SUNSHINE_CLIENT_WIDTH:-}" ]]; then
          printf '%s %s %s\n' "$SUNSHINE_CLIENT_WIDTH" "$SUNSHINE_CLIENT_HEIGHT" "''${SUNSHINE_CLIENT_FPS:-60}" > "$session_file"
        fi
        local width=3840 height=2160 fps=60
        if [[ -s "$session_file" ]]; then
          read -r width height fps < "$session_file"
        fi
        local scale=1
        if (( height >= 2160 )); then
          scale=2
        elif (( height >= 1440 )); then
          scale=1.25
        fi

        if ! hyprctl monitors all -j | jq -e --arg name "$virtual" 'any(.[]; .name == $name)' > /dev/null; then
          hyprctl output create headless "$virtual" > /dev/null
        fi
        hyprctl eval "hl.monitor({output=\"$virtual\", mode=\"''${width}x''${height}@''${fps}\", position=\"auto\", scale=$scale})" > /dev/null

        # Disable the physical outputs only after the virtual one exists, so
        # Hyprland always has a monitor to move workspaces onto. With no other
        # output left, Sunshine's capture selects the virtual monitor.
        hyprctl monitors -j | jq -r --arg name "$virtual" '.[] | select(.name != $name) | .name' |
          while read -r output; do
            hyprctl eval "hl.monitor({output=\"$output\", disabled=true})" > /dev/null
          done
      }

      stop() {
        # Reloading reapplies the declared monitor rules, re-enabling the
        # physical outputs; a disabled headless output cannot be removed.
        hyprctl reload > /dev/null
        hyprctl output remove "$virtual" > /dev/null 2>&1 || true
      }

      # Sunshine only runs prep undo commands when the session is quit, so
      # follow its log to also restore the desk on disconnect and switch back
      # to the virtual monitor when the client resumes the session.
      watch() {
        journalctl --user --unit=sunshine.service --follow --lines=0 --output=cat |
          while read -r line; do
            case "$line" in
              *"CLIENT DISCONNECTED"*) stop || true ;;
              *"CLIENT CONNECTED"*) [[ -s "$session_file" ]] && { start || true; } ;;
            esac
          done
      }

      case "''${1:-}" in
        start) start ;;
        stop) stop ;;
        end) rm -f "$session_file"; stop ;;
        watch) watch ;;
        *) echo "usage: sunshine-display {start|stop|end|watch}" >&2; exit 2 ;;
      esac
    '';
  };
in
{
  environment.systemPackages = [ sunshineDisplay ];

  services.sunshine = {
    enable = true;
    autoStart = true;
    openFirewall = true;

    # Build only Sunshine with CUDA support. Global CUDA support remains off,
    # avoiding CUDA variants of unrelated packages while enabling the RTX
    # 4090's low-latency NVENC path.
    package = pkgs.sunshine.override { cudaSupport = true; };

    # Hyprland exposes the wlroots screencopy protocol, so Sunshine can capture
    # the desktop without the root-equivalent CAP_SYS_ADMIN required by KMS.
    settings = {
      capture = "wlr";
      encoder = "nvenc";
      # No output_name: Sunshine captures the first enabled output. At startup
      # that is a physical monitor, so the encoder probe succeeds; during a
      # stream sunshine-display leaves the virtual monitor as the only one.
      global_prep_cmd = builtins.toJSON [
        {
          do = "${sunshineDisplay}/bin/sunshine-display start";
          undo = "${sunshineDisplay}/bin/sunshine-display end";
        }
      ];
    };
  };

  systemd.user.services.sunshine-display-watch = {
    description = "Restore physical monitors when a Moonlight client disconnects";
    after = [ "sunshine.service" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${sunshineDisplay}/bin/sunshine-display watch";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # Allow Moonlight controllers, keyboards, and mice to be forwarded through
  # Sunshine. The Sunshine NixOS module enables the uinput kernel support.
  users.users.zac.extraGroups = [
    "i2c"
    "uinput"
  ];

  # DDC/CI brightness control darkens the physical panels without disabling
  # the Wayland outputs that Sunshine captures.
  hardware.i2c.enable = true;

  # Linux virtual Xbox/PlayStation controllers use uhid in addition to uinput.
  # Keep the node private to the uinput group and the active local session.
  services.udev.extraRules = ''
    SUBSYSTEM=="misc", KERNEL=="uhid", MODE="0660", GROUP="uinput", TAG+="uaccess"
  '';
}
