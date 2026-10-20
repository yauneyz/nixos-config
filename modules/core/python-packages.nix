{ lib, pkgs, ... }:
let
  pythonSystemEnv = pkgs.python3.withPackages (ps: with ps; [
    # Core packaging tools
    pip
    setuptools
    wheel
    virtualenv

    # System-wide runtimes required by services/scripts
    grpcio
    grpcio-tools
    grpcio-testing

    # Test runners that should always be available
    pytest
    pytest-cov
    pytest-xdist
  ]);
in
{
  environment.systemPackages = [
    pythonSystemEnv
    # The managed vLLM/CUDA wheel environment uses Python 3.12. Keep only
    # its interpreter; general tools use the cached default Python packages.
    (lib.lowPrio pkgs.python312)
  ];
}
