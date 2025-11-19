{ lib
, python3
, fetchFromGitHub
, makeWrapper
, nftables
, iproute2
, conntrack-tools
, util-linux
}:

python3.pkgs.buildPythonApplication rec {
  pname = "focusd";
  version = "0.1.0";
  format = "other";  # We're not using setuptools/pyproject

  # TODO: Replace with fetchFromGitHub when repository is published
  # src = fetchFromGitHub {
  #   owner = "your-github-username";
  #   repo = "focusd";
  #   rev = "v${version}";
  #   sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  # };
  src = /home/zac/development/tools/focus;

  propagatedBuildInputs = with python3.pkgs; [
    pyyaml
    pynacl
  ];

  nativeBuildInputs = [ makeWrapper ];

  # Disable checks as there are no tests
  doCheck = false;

  # Don't use the standard Python build process
  dontUsePythonImportsCheck = true;
  dontUsePythonCatchConflicts = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/libexec/focusd

    # Install Python modules to libexec
    cp -r focusd/*.py $out/libexec/focusd/

    # Install main daemon
    install -Dm755 focusd/focusd.py $out/libexec/focusd/focusd

    # Install CLI tool
    install -Dm755 focusd/cli/focusctl.py $out/libexec/focusd/focusctl

    # Create wrapper scripts that set up Python path
    makeWrapper $out/libexec/focusd/focusd $out/bin/focusd \
      --set PYTHONPATH "$out/libexec/focusd:$PYTHONPATH" \
      --set FOCUSD_NIXOS "1" \
      --prefix PATH : "${lib.makeBinPath [ nftables iproute2 conntrack-tools util-linux ]}"

    makeWrapper $out/libexec/focusd/focusctl $out/bin/focusctl \
      --set PYTHONPATH "$out/libexec/focusd:$PYTHONPATH"

    # Install example configuration files
    mkdir -p $out/share/focusd/examples
    cp focusd/profiles/*.yml $out/share/focusd/examples/ || true

    # Install NixOS helper scripts
    install -Dm755 ${./merge-hosts.sh} $out/bin/focusd-merge-hosts
    install -Dm755 ${./update-firefox.sh} $out/bin/focusd-update-firefox

    runHook postInstall
  '';

  # Patch shebangs and hardcoded paths
  postPatch = ''
    # Update Python imports to work with our install layout
    substituteInPlace focusd/focusd.py \
      --replace-quiet 'sys.path.insert(0, str(_module_dir))' \
                '# Module dir handled by wrapper' || true

    substituteInPlace focusd/cli/focusctl.py \
      --replace-quiet 'sys.path.insert(0, str(_install_path))' \
                '# Install path handled by wrapper' || true
    substituteInPlace focusd/cli/focusctl.py \
      --replace-quiet 'sys.path.insert(0, str(_source_path))' \
                '# Source path handled by wrapper' || true

    # Copy our NixOS-specific modified files
    cp ${./nixos-dns.py} focusd/nixos_dns.py || true
    cp ${./nixos-firefox.py} focusd/nixos_firefox.py || true
  '';

  meta = with lib; {
    description = "Robust distraction blocking system for Linux with DNS sinkholing and transparent proxy";
    longDescription = ''
      focusd is a distraction blocker for Linux that uses:
      - DNS sinkholing via /etc/hosts modification
      - Transparent proxy with SNI inspection for path-level filtering
      - USB key authentication to disable focus mode
      - Emergency recovery codes
      Works on any desktop environment (GNOME, KDE, i3, Wayland, X11).
    '';
    homepage = "https://github.com/your-username/focusd"; # TODO: Update with actual URL
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "focusctl";
  };
}
