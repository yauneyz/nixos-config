{ pkgs, inputs, ... }:

# Talysman browser integration: register the native-messaging host so the
# browser extension can stream live policy from the daemon and enforce
# request-layer blocking (works under ECH/QUIC/VPN). The host binary is part of the
# daemon package; it connects to the daemon's unix socket at /run/talysman.
let
  hostName = "com.talysman.host";
  # Single source of truth: the extension ids live in the snorlax repo and are also
  # baked into the built extensions + native code (native/common/build.rs). Read them
  # from the flake input so this manifest can never drift from the shipped extension.
  # (A mismatch silently blocks the browser from launching the native host.)
  identities = builtins.fromJSON (
    builtins.readFile "${inputs.snorlax}/native/common/extension-identities.json"
  );
  chromiumManifest = builtins.toJSON {
    name = hostName;
    description = "Talysman browser native-messaging host";
    path = "${pkgs.talysman-daemon}/bin/talysman-natmsg";
    type = "stdio";
    allowed_origins = [ "chrome-extension://${identities.chromeStoreId}/" ];
  };
  firefoxManifest = builtins.toJSON {
    name = hostName;
    description = "Talysman browser native-messaging host";
    path = "${pkgs.talysman-daemon}/bin/talysman-natmsg";
    type = "stdio";
    # Firefox uses allowed_extensions; the extension id is set in its manifest.json
    # (browser_specific_settings.gecko.id) → identities.firefoxId.
    allowed_extensions = [ identities.firefoxId ];
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

  # Standalone tray icon (native/linux/src/bin/tray.rs): talks directly to the daemon's socket
  # over D-Bus (ksni, no GTK/libappindicator), so it stays cheap and keeps showing blocking
  # status in the quickshell bar even when the Talysman desktop app itself isn't running.
  systemd.user.services.talysman-tray = {
    Unit = {
      Description = "Talysman tray icon";
      After = [
        "graphical-session-pre.target"
        "hyprland-session.target"
      ];
      PartOf = [ "hyprland-session.target" ];
    };
    Install.WantedBy = [ "hyprland-session.target" ];
    Service = {
      ExecStart = "${pkgs.talysman-daemon}/bin/talysman-tray";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
