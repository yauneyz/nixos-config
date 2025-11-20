{
  pkgs,
  inputs,
  username,
  host,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs username host; };
    users.${username} = {
      imports =
        if (host == "desktop") then
          [ ./../home/default.desktop.nix ]
        else
          [ ./../home ];
      home.username = "${username}";
      home.homeDirectory = "/home/${username}";
      home.stateVersion = "24.05";
      programs.home-manager.enable = true;
    };
    backupFileExtension = "hm-backup";
  };

  users.users.zac = {
    isNormalUser = true;
    description = "zac";
    extraGroups = [
      "networkmanager"
      "nordvpn"
      "wheel"
    ];
    shell = pkgs.zsh;
hashedPassword="";
  };

users.users.frostphoenix = {
isNormalUser = true;
extraGroups = ["wheel" "networkmanager" "nordvpn"];
shell = pkgs.zsh;
hashedPassword = "";
};
  nix.settings.allowed-users = [ "${username}" ];
}
