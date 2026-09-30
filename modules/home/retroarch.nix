{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (wrapRetroArch {
      cores = [
        libretro."mame2003-plus"
        libretro.mgba # Game Boy, Game Boy Color, and Game Boy Advance
      ];
      settings = {
        # Let "instant GBA session" resume exactly where it left off, and
        # save state again on the way out, with no menu interaction.
        savestate_auto_save = "true";
        savestate_auto_load = "true";
        # Local-only command interface so gba-toggle can ask RetroArch to
        # quit cleanly (and thus autosave) instead of killing the process.
        network_cmd_enable = "true";
        network_cmd_port = "55355";
        # config_save_on_exit can persist audio as disabled; force it back on.
        audio_enable = "true";
        audio_mute_enable = "false";
        # The GL driver's vsync on NVIDIA + Wayland locks to 30fps (half speed).
        video_driver = "vulkan";
        fastforward_ratio = "4.0";
      };
    })
  ];
}
