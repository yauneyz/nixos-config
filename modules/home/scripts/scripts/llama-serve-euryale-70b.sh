#!/usr/bin/env bash
set -euo pipefail

models_dir="${ROLEPLAY_MODELS_DIR:-/home/zac/Games/Models/roleplay}"
model="${1:-${LLAMA_EURYALE_70B_MODEL:-$models_dir/L3.3-70B-Euryale-v2.3-Q4_K_M.gguf}}"

if [[ ! -f "$model" ]]; then
  echo "Expected Euryale Q4_K_M GGUF at $model" >&2
  exit 1
fi

host="${LLAMA_HOST:-127.0.0.1}"
port="${LLAMA_PORT:-11434}"
ctx="${LLAMA_CTX_SIZE:-16384}"
threads="${LLAMA_THREADS:-$(nproc)}"
ngl="${LLAMA_N_GPU_LAYERS:-auto}"

extra_args=()
if [[ -n "${LLAMA_SERVER_ARGS:-}" ]]; then
  # Split on spaces intentionally for quick command-line overrides.
  # shellcheck disable=SC2206
  extra_args=(${LLAMA_SERVER_ARGS})
fi

cmd=(
  llama-server
  --model "$model"
  --alias "L3.3-70B-Euryale-v2.3"
  --host "$host"
  --port "$port"
  --ctx-size "$ctx"
  --threads "$threads"
  --parallel 1
  --n-gpu-layers "$ngl"
  --fit on
  --fit-target 2048
  --fit-ctx 8192
  --flash-attn on
  --cache-type-k q8_0
  --cache-type-v q8_0
)

cmd+=("${extra_args[@]}")
exec "${cmd[@]}"
