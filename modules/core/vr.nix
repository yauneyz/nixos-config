{
  config,
  pkgs,
  username,
  ...
}:
let
  steamvrAlvr = pkgs.writeShellScriptBin "steamvr-alvr" ''
    runtime="''${XDG_DATA_HOME:-$HOME/.local/share}/Steam/steamapps/common/SteamVR"
    if [ ! -f "$runtime/bin/vrmonitor.sh" ]; then
      echo "SteamVR not found at $runtime. Install it in the default Steam library." >&2
      exit 1
    fi
    export QT_QPA_PLATFORM=xcb
    exec ${pkgs.bash}/bin/bash "$runtime/bin/vrmonitor.sh" "$@"
  '';

  # ALVR merges this partial session with its version-specific defaults.
  # A starting point for RTX 4090 + Quest 3; tune using headset statistics.
  quest3Baseline = pkgs.writeText "alvr-quest3-baseline.json" (
    builtins.toJSON {
      session_settings = {
        video = {
          preferred_fps = 90.0;
          preferred_codec.variant = "AV1";
          encoder_config = {
            use_10bit = true;
            server_overrides_use_10bit = true;
          };
          transcoding_view_resolution = {
            variant = "Absolute";
            Absolute = {
              width = 2560;
              height.set = false;
            };
          };
          emulated_headset_view_resolution = {
            variant = "Absolute";
            Absolute = {
              width = 2560;
              height.set = false;
            };
          };
          bitrate.mode = {
            variant = "ConstantMbps";
            ConstantMbps = 100;
          };
          foveated_encoding.enabled = true;
        };
        extra = {
          # SteamVR async reprojection is unsupported on this NVIDIA path.
          patches.linux_async_reprojection = false;
          # Networking is configured by NixOS, and the profile is already seeded.
          open_setup_wizard = false;
        };
      };
    }
  );
in
{
  programs.alvr = {
    enable = true;
    # Keep discovery/streaming on the desktop's wired LAN.
    openFirewall = false;
  };

  networking.firewall.interfaces.enp6s0 = {
    allowedTCPPorts = [
      9943
      9944
    ];
    allowedUDPPorts = [
      9943
      9944
    ];
  };

  # Make the same ALVR installation available inside Steam's FHS environment.
  # nixpkgs' ALVR FFmpeg includes NVENC without global cudaSupport.
  programs.steam.extraPackages = [
    config.programs.alvr.package
    steamvrAlvr
  ];

  # Use as SteamVR's launch options: steamvr-alvr %command%
  # ALVR's vrmonitor workaround avoids the incompatible Steam Linux Runtime;
  # xcb lets SteamVR's Qt UI run under Hyprland through XWayland.
  environment.systemPackages = [ steamvrAlvr ];

  home-manager.users.${username} = { config, lib, ... }: {
    # Keep ALVR's live session writable so the dashboard can save tuning and
    # trusted headsets. Rebuilds must not overwrite an existing session.
    xdg.configFile."alvr/quest3-baseline.json".source = quest3Baseline;
    home.activation.alvrQuest3Defaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -e ${lib.escapeShellArg "${config.xdg.configHome}/alvr/session.json"} ]; then
        run ${pkgs.coreutils}/bin/install -Dm600 ${quest3Baseline} \
          ${lib.escapeShellArg "${config.xdg.configHome}/alvr/session.json"}
      fi
    '';

    # Proton's OpenXR games should use SteamVR alongside ALVR's OpenVR driver.
    xdg.configFile."openxr/1/active_runtime.json".source =
      config.lib.file.mkOutOfStoreSymlink "${config.xdg.dataHome}/Steam/steamapps/common/SteamVR/steamxr_linux64.json";
  };
}
