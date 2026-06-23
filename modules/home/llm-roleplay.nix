{ ... }:
{
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
