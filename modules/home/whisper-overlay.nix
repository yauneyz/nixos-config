{ inputs, pkgs, ... }:
{
  imports = [ inputs.whisper-overlay.homeManagerModules.default ];

  home.packages = with pkgs; [
    whisper-overlay
    wtype
  ];

  services.realtime-stt-server.enable = true;
}
