{ pkgs, host, ... }:
{
  networking = {
    hostName = "${host}";
    networkmanager.enable = true;
		nftables.enable = true;
    nameservers = [
      "8.8.8.8"
      "8.8.4.4"
      "1.1.1.1"
    ];
    firewall = {
      enable = true;
      checkReversePath = false;
      allowedTCPPorts = [
        22
        80
        443
        22000 # Syncthing transfers
        59010
        59011
      ];
      allowedUDPPorts = [
        1194 # NordVPN
        21027 # Syncthing discovery
        22000 # Syncthing QUIC
        59010
        59011
      ];
    };
  };

  environment.systemPackages = with pkgs; [ networkmanagerapplet ];
}
