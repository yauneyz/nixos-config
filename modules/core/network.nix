{ lib, pkgs, host, ... }:
{
  networking = {
    hostName = "${host}";
    networkmanager = {
      enable = true;
      # Static LAN address for desktop so services that peers point at by IP
      # (e.g. the kosync KOReader-sync server) don't break when DHCP hands
      # out a different lease. Reuses the address DHCP was already giving
      # this host, so nothing depending on it needs to change.
      ensureProfiles.profiles = lib.mkIf (host == "desktop") {
        enp6s0-static = {
          connection = {
            id = "enp6s0-static";
            type = "ethernet";
            interface-name = "enp6s0";
          };
          ipv4 = {
            method = "manual";
            address1 = "10.1.10.188/24,10.1.10.1";
            dns = "8.8.8.8;8.8.4.4;1.1.1.1;";
          };
          ipv6.method = "auto";
        };
      };
    };
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
        3000 # Talysman development web app (physical-device testing)
        7777 # LAN gaming
        22000 # Syncthing transfers
        17200 # kosync (KOReader progress sync)
        59010
        59011
      ];
      allowedUDPPorts = [
        1194 # NordVPN
        7777 # LAN gaming
        21027 # Syncthing discovery
        22000 # Syncthing QUIC
        59010
        59011
      ];
    };
  };

  environment.systemPackages = with pkgs; [ networkmanagerapplet ];
}
