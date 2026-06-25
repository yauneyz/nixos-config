{ userPaths, ... }:
{
  home.sessionVariables = {
    ZAC_DATA_HOME = userPaths.dataHome;
    NIXOS_CONFIG_DIR = userPaths.nixosConfig;
    USE_SYSTEM_FPM = "true";
    LLAMA_MODELS_DIR = userPaths.models;
    ROLEPLAY_MODELS_DIR = "${userPaths.models}/roleplay";
    TABBYAPI_DIR = "${userPaths.dataHome}/Games/LLM/tabbyAPI";
    HF_HOME = "${userPaths.models}/huggingface";
    EMBEDDINGS_ENDPOINT = "http://127.0.0.1:11435/v1/embeddings";
    EMBEDDINGS_MODEL = "qwen3-embedding-0.6b";
  };
}
