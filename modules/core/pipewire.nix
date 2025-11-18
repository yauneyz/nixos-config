{ pkgs, ... }:
{
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # lowLatency.enable = true;

    wireplumber.configPackages = [
      (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/51-modi-unmute.conf" ''
        monitor.alsa.rules = [
          {
            matches = [
              {
                device.name = "~alsa_card.usb-Schiit_Audio_USB_Modi.*"
              }
            ]
            actions = {
              update-props = {
                api.alsa.soft-mixer = true
              }
            }
          }
        ]

        node.rules = [
          {
            matches = [
              {
                node.name = "~alsa_output.usb-Schiit_Audio_USB_Modi.*"
              }
            ]
            actions = {
              update-props = {
                audio.mute = false
                audio.volume = 0.65
              }
            }
          }
        ]
      '')
      (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/52-bluetooth-auto-switch.conf" ''
        node.rules = [
          {
            matches = [
              {
                node.name = "~bluez_output.*WH-1000XM.*"
              }
            ]
            actions = {
              update-props = {
                priority.driver = 1000
                priority.session = 1000
              }
            }
          }
        ]
      '')
    ];
  };
  hardware.alsa.enablePersistence = true;
  environment.systemPackages = with pkgs; [ pulseaudioFull ];
}
