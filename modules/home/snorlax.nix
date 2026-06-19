{ pkgs, ... }:

# FocusLock (snorlax) browser integration: register the native-messaging host so the
# FocusLock browser extension can stream live policy from the daemon and enforce
# request-layer blocking (works under ECH/QUIC/VPN). The host binary is part of the
# daemon package; it connects to the daemon's unix socket at /run/focuslock.
let
  hostName = "com.focuslock.host";
  manifest = builtins.toJSON {
    name = hostName;
    description = "FocusLock browser native-messaging host";
    path = "${pkgs.snorlax-daemon}/bin/focuslock-natmsg";
    type = "stdio";
    # Firefox uses allowed_extensions; the extension id is set in its manifest.json
    # (browser_specific_settings.gecko.id).
    allowed_extensions = [ "focuslock@focuslock.app" ];
  };
in
{
  # Firefox on Linux looks up native-messaging hosts in ~/.mozilla/native-messaging-hosts.
  home.file.".mozilla/native-messaging-hosts/${hostName}.json".text = manifest;
}
