{
  inputs,
  lib,
  username,
  ...
}:
let
  secretsFile = ../../secrets/secrets.yaml;
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  # Encrypted secrets committed to the repo, decrypted to /run/secrets at
  # activation. One personal age key is shared by every host; copy
  # ~/.config/sops/age/keys.txt to a new machine before its first rebuild.
  #
  #   sops secrets/secrets.yaml      # edit (recipients come from .sops.yaml)
  #
  # Then declare each secret below and reference
  # config.sops.secrets.<name>.path from the consuming module.
  sops = {
    age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
    age.sshKeyPaths = [ ];
    gnupg.sshKeyPaths = [ ];

    defaultSopsFile = lib.mkIf (builtins.pathExists secretsFile) secretsFile;

    # atuin's history encryption key, shared by every host so they can all
    # decrypt each other's synced history (modules/home/atuin.nix: key_path).
    secrets.atuin_key = {
      owner = username;
      mode = "0400";
    };
  };
}
