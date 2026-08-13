{ pkgs, lib, ... }:
{
  # OBS doesn't expose a "minimize to tray" toggle in its own config unless
  # you've already opened Settings > General once. Pre-seed it so the tray
  # icon is there and closing the window docks it instead of quitting, the
  # first time you launch OBS.
  home.activation.obsSystemTray = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    obs_ini="$HOME/.config/obs-studio/global.ini"
    ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$obs_ini")"
    ${pkgs.coreutils}/bin/touch "$obs_ini"
    if ${pkgs.gnugrep}/bin/grep -q '^\[BasicWindow\]' "$obs_ini"; then
      if ${pkgs.gnugrep}/bin/grep -qE '^SystemTrayHideMinimize=' "$obs_ini"; then
        ${pkgs.gnused}/bin/sed -i 's/^SystemTrayHideMinimize=.*/SystemTrayHideMinimize=true/' "$obs_ini"
      else
        ${pkgs.gnused}/bin/sed -i '/^\[BasicWindow\]/a SystemTrayHideMinimize=true' "$obs_ini"
      fi
    else
      printf '\n[BasicWindow]\nSystemTrayHideMinimize=true\n' >> "$obs_ini"
    fi
  '';
}
