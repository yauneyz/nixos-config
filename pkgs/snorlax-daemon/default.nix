{ lib
, rustPlatform
, snorlaxSrc
}:

# Privileged Linux enforcement daemon for Talysman. Builds the Rust crate
# under native/linux from the snorlax source input and produces these binaries:
#   talysman-svc      - the daemon started by the declarative systemd unit
#   talysman-svcctl   - service control + recovery-code generation CLI
#   talysman-recover  - out-of-band recovery killswitch
#   talysman-natmsg   - browser native-messaging host (com.talysman.host)
#   focus-enable       - toggle focus blocking on  (RPC enableFocus)
#   focus-disable      - toggle focus blocking off (RPC disableFocus; needs USB key)
#   focus-toggle       - toggle focus blocking (RPC toggleFocus; off needs USB key)
# All land in $out/bin as siblings, so svcctl's current_exe()-relative lookup of
# talysman-svc still resolves. The daemon shells out to `nft`/`ip` at runtime; those
# are provided on PATH by the systemd unit (modules/core/snorlax.nix), not linked here.
rustPlatform.buildRustPackage {
  pname = "talysman-daemon";
  version = "0.1.0";

  # Keep the repository layout intact: native/linux has a ../common path
  # dependency and the tray binary embeds icons from apps/desktop/resources.
  src = snorlaxSrc;
  cargoRoot = "native/linux";
  buildAndTestSubdir = "native/linux";

  cargoLock.lockFile = snorlaxSrc + "/native/linux/Cargo.lock";

  meta = with lib; {
    description = "Talysman privileged Linux enforcement daemon";
    homepage = "https://talysman.app";
    license = licenses.mit;
    mainProgram = "talysman-svc";
    platforms = platforms.linux;
  };
}
