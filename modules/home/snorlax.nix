{ pkgs, ... }:

# Talysman browser integration: register the native-messaging host so the
# browser extension can stream live policy from the daemon and enforce
# request-layer blocking (works under ECH/QUIC/VPN). The host binary is part of the
# daemon package; it connects to the daemon's unix socket at /run/talysman.
let
  hostName = "com.talysman.host";
  chromiumManifest = builtins.toJSON {
    name = hostName;
    description = "Talysman browser native-messaging host";
    path = "${pkgs.talysman-daemon}/bin/talysman-natmsg";
    type = "stdio";
    allowed_origins = [ "chrome-extension://fjohodlenndbieegdcbpblcjkncdngpb/" ];
  };
  firefoxManifest = builtins.toJSON {
    name = hostName;
    description = "Talysman browser native-messaging host";
    path = "${pkgs.talysman-daemon}/bin/talysman-natmsg";
    type = "stdio";
    # Firefox uses allowed_extensions; the extension id is set in its manifest.json
    # (browser_specific_settings.gecko.id).
    allowed_extensions = [ "talysman@talysman.app" ];
  };
in
{
  # Firefox on Linux looks up native-messaging hosts in ~/.mozilla/native-messaging-hosts.
  home.file.".mozilla/native-messaging-hosts/${hostName}.json" = {
    text = firefoxManifest;
    force = true;
  };

  # Chromium browsers use the NativeMessagingHosts directory within their user-data root.
  home.file.".config/google-chrome/NativeMessagingHosts/${hostName}.json" = {
    text = chromiumManifest;
    force = true;
  };
  home.file.".config/google-chrome-for-testing/NativeMessagingHosts/${hostName}.json" = {
    text = chromiumManifest;
    force = true;
  };
  home.file.".config/chromium/NativeMessagingHosts/${hostName}.json" = {
    text = chromiumManifest;
    force = true;
  };
  home.file.".config/microsoft-edge/NativeMessagingHosts/${hostName}.json" = {
    text = chromiumManifest;
    force = true;
  };
}
