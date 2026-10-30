{
  version = "0.8.0";
  addonId = "talysman-firefox@talysman.app";
  src = builtins.fetchurl {
    url = "file:///nix/store/8ynzw143s0gv4rbyw112xx98dmclcx1f-talysman-firefox.xpi";
    sha256 = "17mbwz4jz6pdxxinm95v8q8n5wx7150sn1mq5f8sdcqv2rs22hj7";
  };
}
