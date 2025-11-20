{ pkgs, ... }:

{
  # Machine Learning and AI packages
  # Note: CUDA support is enabled on desktop only (modules/core/nixpkgs.nix)
  # Desktop: PyTorch with CUDA | Laptop: PyTorch CPU-only
  # Initial build on desktop: ~2 hours, but subsequent rebuilds use cache

  home.packages = with pkgs.python312Packages; [
    # Deep Learning Framework (with CUDA support via global config)
    torch
    torchvision

    # vLLM - High-performance LLM inference engine
    # WARNING: Uncomment below to enable vLLM
    # Initial build is ~2 hours, but only needs to happen once
    # Once built, toggling vLLM on/off is fast
    # vllm

    # HuggingFace libraries
    transformers
    datasets
    huggingface-hub
    tokenizers

    # Additional ML utilities
    accelerate      # Distributed training and inference
    safetensors     # Safe tensor serialization
  ];

  # Environment variables for ML work
  home.sessionVariables = {
    # Optimize PyTorch for performance
    OMP_NUM_THREADS = "1";  # Prevent oversubscription in multiprocessing

    # HuggingFace cache location
    HF_HOME = "$HOME/.cache/huggingface";

    # CUDA cache location
    CUDA_CACHE_PATH = "$HOME/.cache/cuda";
  };
}
