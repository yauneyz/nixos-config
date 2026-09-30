{
  version = "0.6.1";
  addonId = "talysman-firefox@talysman.app";
  src = builtins.fetchurl {
    url = "file:///nix/store/assr1zr1r56klmv6dafw2asmx0zy3fp0-talysman-firefox.xpi";
    sha256 = "003yqybwzqhjhkfg5zxpx9qsxr955bka26590az9jqvcfspql7h4";
  };
}
