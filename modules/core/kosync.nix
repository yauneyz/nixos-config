{ host, ... }:
{
  # Self-hosted KOReader progress-sync server (kosync). Lets any device
  # running KOReader (Kindle included, once koreader is installed there)
  # sync reading position against this machine instead of koreader.rocks.
  # Plain HTTP port — this only needs to be reachable on the LAN.
  #
  # Backend pinned to docker: this host already runs the Docker daemon
  # (modules/core/virtualization.nix) and oci-containers defaults to podman,
  # which would otherwise install a second, unused container runtime.
  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers.kosync = {
    autoStart = host == "desktop";
    image = "koreader/kosync:latest";
    ports = [ "17200:17200" ];
    volumes = [
      "/var/lib/kosync/app-logs:/app/koreader-sync-server/logs"
      "/var/lib/kosync/redis-logs:/var/log/redis"
      "/var/lib/kosync/redis-data:/var/lib/redis"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/kosync/app-logs 0750 root root -"
    "d /var/lib/kosync/redis-logs 0750 root root -"
    "d /var/lib/kosync/redis-data 0750 root root -"
  ];
}
