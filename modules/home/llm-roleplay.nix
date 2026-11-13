{ pkgs, ... }:
let
  tavernHelper = pkgs.writeText "tavern-serve.py" (builtins.readFile ./scripts/scripts/tavern-serve.py);
  tavernStack = pkgs.writeShellApplication {
    name = "tavern-stack";
    runtimeInputs = [ pkgs.python3 pkgs.xdg-utils ];
    text = ''
      export TAVERN_NODE=${pkgs.nodejs-patched}/bin/node
      export TAVERN_FRONTEND_ENTRY=${pkgs.sillytavern}/lib/node_modules/sillytavern/src/server-global.js
      export TAVERN_DEFAULT_SETTINGS=${pkgs.sillytavern}/lib/node_modules/sillytavern/default/content/settings.json
      exec python3 ${tavernHelper} "$@"
    '';
  };
in
{
  # textgen provides its llama.cpp model loader and browser configuration UI;
  # the CUDA-enabled system llama-server remains available through llm-serve.
  home.packages = [ tavernStack ];

  # TabbyAPI serves the EXL3 Cydonia model to SillyTavern through either its
  # OpenAI-compatible or Kobold-compatible API. Keep it local-only because
  # authentication is intentionally disabled for convenient desktop use.
  xdg.configFile."tabbyAPI/config.yml".text = ''
    network:
      host: 127.0.0.1
      port: 5000
      disable_auth: true
      disable_fetch_requests: true
      api_servers: ["OAI", "Kobold"]

    model:
      model_dir: /home/zac/Games/Models/roleplay
      model_name: Cydonia-24B-v4.3-EXL3-5.0bpw
      backend: exllamav3
      max_seq_len: 24576
      cache_size: 24576
      cache_mode: 8,8
      chunk_size: 2048
      output_chunking: true
      max_batch_size: 1

    sampling:
      override_preset: safe_defaults
  '';
}
