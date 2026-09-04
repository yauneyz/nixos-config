{ ... }:
{
  services.jellyfin = {
    enable = true;

    # Access is limited to the interfaces below; nothing is forwarded through
    # the router or exposed directly to the public internet.
    openFirewall = false;

    # Keep the library database, artwork, and transcode cache on the large data
    # partition rather than the root filesystem.
    dataDir = "/data/jellyfin";
    cacheDir = "/data/jellyfin/cache";

    hardwareAcceleration = {
      enable = true;
      type = "nvenc";
      device = "/dev/nvidia0";
    };

    # Make the NixOS configuration authoritative for transcoding. The RTX 4090
    # supports hardware decode and encode for all codecs enabled here.
    forceEncodingConfig = true;
    transcoding = {
      enableHardwareEncoding = true;
      enableToneMapping = true;
      enableSubtitleExtraction = true;

      hardwareDecodingCodecs = {
        h264 = true;
        hevc = true;
        hevc10bit = true;
        mpeg2 = true;
        vc1 = true;
        vp8 = true;
        vp9 = true;
        av1 = true;
      };

      hardwareEncodingCodecs = {
        hevc = true;
        av1 = true;
      };
    };
  };

  # Media files normally inherit the users group. The video/render groups
  # provide access to the NVIDIA device nodes used for transcoding.
  users.users.jellyfin.extraGroups = [
    "users"
    "video"
    "render"
  ];

  # Ensure the bind-mounted media directory is available before Jellyfin starts.
  systemd.services.jellyfin.unitConfig.RequiresMountsFor = [ "/home/zac/Videos" ];

  # Enabling DeviceAllow switches systemd to a closed device policy. The NixOS
  # module admits the selected GPU, and NVENC/NVDEC also need NVIDIA's control,
  # UVM, and modeset nodes to submit work to it.
  systemd.services.jellyfin.serviceConfig.DeviceAllow = [
    "/dev/nvidiactl rw"
    "/dev/nvidia-modeset rw"
    "/dev/nvidia-uvm rw"
    "/dev/nvidia-uvm-tools rw"
  ];

  networking.firewall.interfaces = {
    enp6s0 = {
      allowedTCPPorts = [ 8096 ];
      allowedUDPPorts = [ 7359 ];
    };
    tailscale0.allowedTCPPorts = [ 8096 ];
  };
}
