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
  version = "unstable-2024-11-20";
  format = "other";  # We're not using setuptools/pyproject

  src = fetchFromGitHub {
    owner = "yauneyz";
    repo = "focusd";
    rev = "294339763c79ccf2d2284d1cf30f61eaf18f7008";
    sha256 = "sha256-iItSE8uGfbw/cEe6mBeKn0FEtChfZOzMCUmx93eERsE=";
  };

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
      --prefix PATH : "${lib.makeBinPath [ nftables iproute2 conntrack-tools util-linux ]}"

    makeWrapper $out/libexec/focusd/focusctl $out/bin/focusctl \
      --set PYTHONPATH "$out/libexec/focusd:$PYTHONPATH"

    # Install example configuration files
    mkdir -p $out/share/focusd/examples
    cp focusd/profiles/*.yml $out/share/focusd/examples/ || true

    runHook postInstall
  '';

  # Patch shebangs and hardcoded paths
  postPatch = ''
    # Update Python imports to work with our install layout
    substituteInPlace focusd/focusd.py \
      --replace-quiet 'sys.path.insert(0, str(_module_dir))' \
                'pass  # Module dir handled by wrapper' || true

    substituteInPlace focusd/cli/focusctl.py \
      --replace-quiet 'sys.path.insert(0, str(_install_path))' \
                'pass  # Install path handled by wrapper' || true
    substituteInPlace focusd/cli/focusctl.py \
      --replace-quiet 'sys.path.insert(0, str(_source_path))' \
                'pass  # Source path handled by wrapper' || true
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
    homepage = "https://github.com/yauneyz/focusd";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "focusctl";
  };
}
