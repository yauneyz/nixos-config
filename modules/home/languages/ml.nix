{ pkgs, host, ... }:

let
  # Enable CUDA only on desktop (has NVIDIA GPU)
  cudaEnabled = host == "desktop";

  # Override Python packages with CUDA support when on desktop
  pythonPackages = if cudaEnabled then
    pkgs.python312Packages.override {
      overrides = self: super: {
        # Override PyTorch with CUDA support
        pytorch = super.pytorch.override {
          cudaSupport = true;
        };

        # Override vLLM with CUDA support
        # vllm = super.vllm.override {
        #   cudaSupport = true;
        # };
      };
    }
  else
    pkgs.python312Packages;

in
{
  home.packages = with pythonPackages; [
    # Deep Learning Framework
    torch
    torchvision

    # vLLM - High-performance LLM inference engine
    # vllm

    # HuggingFace libraries
    transformers
    datasets
    huggingface-hub
    tokenizers

    # Additional ML utilities
    accelerate  # Distributed training and inference
    safetensors # Safe tensor serialization
  ];

  # Set environment variables for ML work
  home.sessionVariables = {
    # Optimize PyTorch for performance
    OMP_NUM_THREADS = "1";  # Prevent oversubscription in multiprocessing

    # HuggingFace cache location
    HF_HOME = "$HOME/.cache/huggingface";
  } // (if cudaEnabled then {
    # CUDA-specific environment variables
    CUDA_CACHE_PATH = "$HOME/.cache/cuda";
  } else {});
}
