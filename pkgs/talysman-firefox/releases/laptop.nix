{
  version = "0.8.1";
  addonId = "talysman-firefox@talysman.app";
  src = builtins.fetchurl {
    url = "file:///nix/store/mn3l5gf8r8anqihsa0h2c9wnwciqcwd2-talysman-firefox.xpi";
    sha256 = "1zwzvmnr8w7h2ycvxfh6d833bcl5ld32g7kd9mn4ifprqzh6v60j";
  };
}
