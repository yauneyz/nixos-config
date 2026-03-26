{ lib, host, ... }:
{
  services.syncthing = lib.mkIf (host == "desktop" || host == "laptop") {
    enable = true;
    user = "zac";
    dataDir = "/home/zac";
    configDir = "/home/zac/.config/syncthing";

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
