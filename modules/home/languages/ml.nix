{ pkgs, userPaths, ... }:

{
  # Optional CPU ML tools use nixpkgs' default Python for binary cache reuse.
  # CUDA PyTorch/vLLM workloads use the separate ml-env wheel environment.

  home.packages = with pkgs.python3Packages; [
    # CPU frameworks; CUDA is deliberately not enabled globally.
    torch
    torchvision

    # vLLM - High-performance LLM inference engine
    # WARNING: Uncomment below to enable vLLM
    # Prefer the vllm-serve/ml-env launchers to reuse prebuilt CUDA wheels.
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
    HF_HOME = "${userPaths.models}/huggingface";

    # CUDA cache location
    CUDA_CACHE_PATH = "${userPaths.dataHome}/.cache/cuda";
  };
}
