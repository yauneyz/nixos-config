{ pkgs, ... }:
{
  home.packages = with pkgs; [ vlc ];

  # Declarative VLC config. Note: this symlinks vlcrc read-only into the Nix
  # store, so changes made through VLC's GUI preferences won't persist — tweak
  # settings here instead.
  #
  # "Coach scrubbing": , and . jump back / forward. Add modifiers for bigger
  # jumps, so the same two keys give an escalating scrub speed:
  #        , / .   ->  2s   (fine)
  #   Shift + , .  -> 10s   (faster)
  #    Ctrl + , .  -> 30s   (fastest)
  xdg.configFile."vlc/vlcrc".text = ''
    [core] # core program

    # Keep VLC's first-run prompts dismissed
    qt-privacy-ask=0
    metadata-network-access=1

    # Jump durations (seconds)
    extrashort-jump-size=2
    short-jump-size=10
    medium-jump-size=30

    # Escalating scrub on , (back) and . (forward)
    key-jump-extrashort=,
    key-jump+extrashort=.
    key-jump-short=Shift+,
    key-jump+short=Shift+.
    key-jump-medium=Ctrl+,
    key-jump+medium=Ctrl+.
  '';
}
