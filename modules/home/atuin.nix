_:
{
  # Shell history in SQLite, synced (end-to-end encrypted) between desktop and
  # laptop through the self-hosted server in modules/core/atuin-server.nix.
  #
  #   Ctrl-R          full-screen search (Ctrl-R again cycles global/host/session/directory)
  #   Tab             put the selected command on the prompt to edit
  #   Enter           run it
  #   atuin stats     what you actually type the most
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    # Keep Up-arrow as zsh's prefix history search (zsh_keybinds.nix).
    flags = [ "--disable-up-arrow" ];

    settings = {
      # Desktop's Tailscale address (same pin as modules/home/ssh.nix).
      sync_address = "http://100.72.178.46:8888";
      auto_sync = true;
      sync_frequency = "5m";
      sync.records = true;
      # Shared encryption key, decrypted by sops-nix (modules/core/sops.nix).
      key_path = "/run/secrets/atuin_key";
      update_check = false;

      search_mode = "fuzzy";
      filter_mode = "global";
      workspaces = true; # in a git repo, "workspace" filter = that repo
      style = "compact";
      inline_height = 25;
      show_preview = true;
      enter_accept = true;
      keymap_mode = "emacs";

      # Never record commands that put credentials on the command line.
      secrets_filter = true;
      history_filter = [
        "^export [A-Z_]*(KEY|TOKEN|SECRET|PASSWORD|PASS)[A-Z_]*="
        "^[A-Z_]*(KEY|TOKEN|SECRET|PASSWORD)[A-Z_]*=\\S+ "
      ];
      # Don't record noise.
      cwd_filter = [ "^/tmp" ];
    };
  };
}
