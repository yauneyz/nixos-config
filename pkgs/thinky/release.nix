let
  url = "file:///nix/store/82r6l29i2nl25cig4k4s8k5crnhzkqyc-thinky.AppImage";
  sha256 = "05688j0dhvgb8zhv9fi4qq41nb948kxsihzxr1skrd5zwajx6jls";
in
{
  version = "1.0.42";
  available = true;
  inherit url sha256;

  storePath = builtins.fetchurl { inherit url sha256; };
}
