{
  version = "0.7.0";
  addonId = "talysman-firefox@talysman.app";
  src = builtins.fetchurl {
    url = "file:///nix/store/ms538ala1y7lj4p87zgpbm93cf0c8jbi-talysman-firefox.xpi";
    sha256 = "1gq0d8bqp3zp536i2ax42ck1x39r0jk7gklh3byw82bgsy59asgl";
  };
}
