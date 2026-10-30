{ pkgs, inputs, ... }:
let
  # Superfile requires Go 1.26; its flake's gomod2nix builder defaults to an
  # older compiler, whose automatic toolchain download fails in the sandbox.
  goPkgs = pkgs.extend inputs.superfile.inputs.gomod2nix.overlays.default;
  upstream = inputs.superfile.packages.${pkgs.stdenv.hostPlatform.system}.default;
  superfile = goPkgs.buildGoApplication {
    inherit (upstream) pname version;
    src = inputs.superfile;
    modules = inputs.superfile + "/gomod2nix.toml";
    go = pkgs.go_1_26;
    doCheck = false;
  };
in
{
  home.packages = [ superfile ];

  xdg.configFile."superfile/config.toml".source = ./config.toml;
}
