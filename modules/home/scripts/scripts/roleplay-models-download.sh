#!/usr/bin/env bash
set -euo pipefail

models_dir="${ROLEPLAY_MODELS_DIR:-/home/zac/Games/Models/roleplay}"
cydonia_dir="$models_dir/Cydonia-24B-v4.3-EXL3-5.0bpw"

if ! command -v uvx >/dev/null 2>&1; then
  echo "uvx is required; apply the Home Manager configuration first." >&2
  exit 1
fi

mkdir -p "$models_dir"
export HF_HOME="${HF_HOME:-/home/zac/Games/Models/huggingface}"
export UV_CACHE_DIR="${UV_CACHE_DIR:-/home/zac/Games/LLM/uv-cache}"

uvx --from huggingface_hub hf download \
  ArtusDev/TheDrummer_Cydonia-24B-v4.3-EXL3 \
  --revision 5.0bpw_H6 \
  --local-dir "$cydonia_dir"

uvx --from huggingface_hub hf download \
  bartowski/L3.3-70B-Euryale-v2.3-GGUF \
  L3.3-70B-Euryale-v2.3-Q4_K_M.gguf \
  --local-dir "$models_dir"
