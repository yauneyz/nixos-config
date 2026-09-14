{ pkgs, ... }:
let
  mgbaCore = "${pkgs.libretro.mgba}/lib/retroarch/cores/mgba_libretro.so";

  gbaToggle = pkgs.writeShellApplication {
    name = "gba-toggle";
    runtimeInputs = [
      pkgs.rofi
      pkgs.libnotify
      pkgs.procps
    ];
    text = ''
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/gba-toggle"
      runtime_dir="''${XDG_RUNTIME_DIR:-/tmp}"
      mkdir -p "$state_dir"

      pid_file="$runtime_dir/gba-toggle.pid"
      last_rom_file="$state_dir/last-rom"
      roms_dir="$HOME/Games/Retroid"
      cmd_port=55355
      mgba_core="${mgbaCore}"

      is_session_running() {
        [ -f "$pid_file" ] || return 1
        local pid
        pid="$(cat "$pid_file")"
        [ -n "$pid" ] && [ -d "/proc/$pid" ] || return 1
        [ "$(cat "/proc/$pid/comm" 2>/dev/null || true)" = "retroarch" ]
      }

      quit_session() {
        local pid
        pid="$(cat "$pid_file")"

        # Ask RetroArch to quit through its command interface so it runs
        # its normal shutdown path (and writes the auto save state).
        echo -n "QUIT" > "/dev/udp/127.0.0.1/$cmd_port" 2>/dev/null || true

        for _ in $(seq 1 50); do
          [ -d "/proc/$pid" ] || break
          sleep 0.1
        done

        # Fallback: SIGTERM is handled by RetroArch as a normal quit request.
        if [ -d "/proc/$pid" ]; then
          kill -TERM "$pid" 2>/dev/null || true
          for _ in $(seq 1 30); do
            [ -d "/proc/$pid" ] || break
            sleep 0.1
          done
        fi

        rm -f "$pid_file"
      }

      pick_rom() {
        mapfile -t roms < <(
          find "$roms_dir" -type f \( -iname '*.gba' -o -iname '*.zip' \) 2>/dev/null | sort
        )
        if [ "''${#roms[@]}" -eq 0 ]; then
          return 1
        fi

        local choice
        choice="$(printf '%s\n' "''${roms[@]#"$roms_dir"/}" | rofi -dmenu -i -p "GBA Game")" || return 1
        [ -n "$choice" ] || return 1
        printf '%s' "$roms_dir/$choice"
      }

      launch_session() {
        local rom=""
        if [ -f "$last_rom_file" ]; then
          rom="$(cat "$last_rom_file")"
          [ -f "$rom" ] || rom=""
        fi

        if [ -z "$rom" ]; then
          rom="$(pick_rom)" || rom=""
        fi

        if [ -z "$rom" ] || [ ! -f "$rom" ]; then
          notify-send "GBA" "No ROM selected" || true
          exit 1
        fi

        printf '%s' "$rom" > "$last_rom_file"

        setsid retroarch -L "$mgba_core" "$rom" >/dev/null 2>&1 &
        disown || true
        echo $! > "$pid_file"
      }

      if is_session_running; then
        quit_session
      else
        rm -f "$pid_file"
        launch_session
      fi
    '';
  };
in
{
  home.packages = [ gbaToggle ];
}
