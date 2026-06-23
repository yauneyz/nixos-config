#!/usr/bin/env bash
set -euo pipefail

tabby_dir="${TABBYAPI_DIR:-/home/zac/Games/LLM/tabbyAPI}"
config="${TABBYAPI_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/tabbyAPI/config.yml}"
model_dir="${ROLEPLAY_MODELS_DIR:-/home/zac/Games/Models/roleplay}"
model_name="${TABBYAPI_MODEL:-Cydonia-24B-v4.3-EXL3-5.0bpw}"

if [[ ! -f "$tabby_dir/start.sh" ]]; then
  echo "TabbyAPI is not installed at $tabby_dir" >&2
  echo "Re-run the roleplay model setup or set TABBYAPI_DIR." >&2
  exit 1
fi

if [[ ! -f "$config" ]]; then
  echo "TabbyAPI config not found: $config" >&2
  echo "Apply the Home Manager configuration first or set TABBYAPI_CONFIG." >&2
  exit 1
fi

if [[ ! -f "$model_dir/$model_name/config.json" ]]; then
  echo "Cydonia EXL3 model not found at $model_dir/$model_name" >&2
  exit 1
fi

# Python CUDA wheels need both their bundled libraries and the live NixOS
# NVIDIA driver library at runtime.
library_paths=()
if [[ -n "${NIX_LD_LIBRARY_PATH:-}" ]]; then
  library_paths+=("$NIX_LD_LIBRARY_PATH")
fi
if [[ -d /run/opengl-driver/lib ]]; then
  library_paths+=("/run/opengl-driver/lib")
  export TRITON_LIBCUDA_PATH="${TRITON_LIBCUDA_PATH:-/run/opengl-driver/lib}"
fi
shopt -s nullglob
for library_dir in \
  "$tabby_dir"/venv/lib/python*/site-packages/torch/lib \
  "$tabby_dir"/venv/lib/python*/site-packages/nvidia/*/lib
do
  library_paths+=("$library_dir")
done
shopt -u nullglob
if [[ -n "${LD_LIBRARY_PATH:-}" ]]; then
  library_paths+=("$LD_LIBRARY_PATH")
fi
if (( ${#library_paths[@]} > 0 )); then
  old_ifs="$IFS"
  IFS=:
  export LD_LIBRARY_PATH="${library_paths[*]}"
  IFS="$old_ifs"
fi

export HF_HOME="${HF_HOME:-/home/zac/Games/Models/huggingface}"
export UV_CACHE_DIR="${UV_CACHE_DIR:-/home/zac/Games/LLM/uv-cache}"
mkdir -p "$HF_HOME" "$UV_CACHE_DIR"

cd "$tabby_dir"
exec ./start.sh --gpu-lib cu12 --config "$config" "$@"
