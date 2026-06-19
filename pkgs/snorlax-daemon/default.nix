{ lib
, rustPlatform
, snorlaxSrc
}:

# Privileged Linux enforcement daemon for FocusLock (snorlax). Builds the Rust crate
# at native/linux from the snorlax flake input and produces these binaries:
#   focuslock-svc      - the daemon started by the declarative systemd unit
#   focuslock-svcctl   - service control + recovery-code generation CLI
#   focuslock-recover  - out-of-band recovery killswitch
#   focuslock-natmsg   - browser native-messaging host (com.focuslock.host)
#   focus-enable       - toggle focus blocking on  (RPC enableFocus)
#   focus-disable      - toggle focus blocking off (RPC disableFocus; needs USB key)
# All land in $out/bin as siblings, so svcctl's current_exe()-relative lookup of
# focuslock-svc still resolves. The daemon shells out to `nft`/`ip` at runtime; those
# are provided on PATH by the systemd unit (modules/core/snorlax.nix), not linked here.
rustPlatform.buildRustPackage {
  pname = "focuslock-daemon";
  version = "0.1.0";

  src = snorlaxSrc + "/native/linux";

  cargoLock.lockFile = snorlaxSrc + "/native/linux/Cargo.lock";

  meta = with lib; {
    description = "FocusLock privileged Linux enforcement daemon (snorlax backend)";
    homepage = "https://focuslock.app";
    license = licenses.mit;
    mainProgram = "focuslock-svc";
    platforms = platforms.linux;
  };
}
