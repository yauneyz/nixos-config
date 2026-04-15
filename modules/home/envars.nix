{ ... }:
{
  home.sessionVariables = {
    USE_SYSTEM_FPM = "true";
    LLAMA_MODELS_DIR = "/home/zac/Games/Models";
    HF_HOME = "$HOME/.cache/huggingface";
    EMBEDDINGS_ENDPOINT = "http://127.0.0.1:11435/v1/embeddings";
    EMBEDDINGS_MODEL = "qwen3-embedding-0.6b";
  };
}
