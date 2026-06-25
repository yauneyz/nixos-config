{ pkgs, ... }:
{
  hardware.steam-hardware.enable = true;
  hardware.xpadneo.enable = true;

  programs = {
    steam = {
      enable = true;
      protontricks.enable = true;

      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = false;

      gamescopeSession.enable = true;

      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };

    gamescope = {
      enable = true;
      capSysNice = false;
      args = [
        "--rt"
        "--expose-wayland"
      ];
    };
  };

  services.udev.extraRules = ''
    # Nintendo Switch Pro Controller over USB-C
    KERNEL=="hidraw*", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="2009", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="057e", ATTR{idProduct}=="2009", ENV{ID_INPUT_JOYSTICK}="1", TAG+="uaccess"
  '';
}
