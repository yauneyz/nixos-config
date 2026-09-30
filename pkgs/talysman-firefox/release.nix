{ host }:

let
  releaseFile = ./releases + "/${host}.nix";
in
if builtins.pathExists releaseFile then
  import releaseFile
else
  {
    version = "unavailable";
    available = false;
  }
