{
  config,
  lib,
  host,
  ...
}:
{
  services.syncthing = lib.mkIf (host == "desktop" || host == "laptop") {
    enable = true;
    user = "zac";
    dataDir = config.zac.paths.dataHome;
    configDir = "${config.zac.paths.home}/.config/syncthing";

    overrideDevices = false;
    overrideFolders = false;

    settings = {
      options = {
        urAccepted = -1; # Disable usage reporting prompt
      };
      gui = {
        insecureSkipHostcheck = false;
      };
    };
  };
}
