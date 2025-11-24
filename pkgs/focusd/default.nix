{ lib
, buildGoModule
, nftables
, focusdSrc
}:

buildGoModule rec {
  pname = "focusd";
  version = "0.1.0";

  # Use the focusd source from flake input
  src = focusdSrc;

  vendorHash = "sha256-4MwBYiQBii4lE55qmGfsp/p9lqj1JlulGykd605+swg=";

  # Build only the main binary
  subPackages = [ "cmd/focusd" ];

  ldflags = [
    "-s"
    "-w"
  ];

  # Runtime dependencies
  buildInputs = [ nftables ];

  meta = with lib; {
    description = "A distraction blocker with DNS and nftables integration";
    longDescription = ''
      focusd is a distraction blocker for NixOS that uses:
      - DNS blocking via dnsmasq
      - IP-level blocking via nftables
      - USB key authentication for enable/disable
      - Persistent state across reboots

      Blocks distracting websites at both DNS and network layers.
    '';
    homepage = "https://github.yauneyz.com/focusd";
    license = licenses.mit;
    mainProgram = "focusd";
    platforms = platforms.linux;
  };
}
