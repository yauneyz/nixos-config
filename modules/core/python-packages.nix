{ pkgs, ... }:
let
  pythonSystemEnv = pkgs.python312.withPackages (ps: with ps; [
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
  ];
}
