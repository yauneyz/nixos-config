{
  version = "0.6.1";
  addonId = "talysman-firefox@talysman.app";
  src = builtins.fetchurl {
    url = "file:///nix/store/by6y97r1yc378pa1yrsv6hwbhnbsc6y4-talysman-firefox.xpi";
    sha256 = "0yv7hz4gmy53qsfiwpswq76s4a3s7pwixc8gabjmnpksb2f8iy77";
  };
}
