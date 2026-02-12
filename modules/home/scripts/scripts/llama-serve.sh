#!/usr/bin/env bash
set -euo pipefail

models_dir="${LLAMA_MODELS_DIR:-$HOME/.local/share/llama.cpp/models}"
mkdir -p "$models_dir"

model="${1:-}"
if [[ -n "$model" ]]; then
  if [[ ! -f "$model" ]]; then
    echo "Model file not found: $model" >&2
    exit 1
  fi
else
  model="$(ls -1t "$models_dir"/*.gguf 2>/dev/null | head -n 1 || true)"
  if [[ -z "$model" ]]; then
    cat >&2 <<EOF
No .gguf models found in $models_dir
Drop a model there (e.g. *.gguf) or pass a path as the first argument.
EOF
    exit 1
  fi
fi

port="${LLAMA_PORT:-11434}"
threads="${LLAMA_THREADS:-$(nproc)}"
ctx="64000"
ngl=""
fit=""

host="$(hostname)"
if [[ "$host" == "desktop" ]]; then
  # Let llama.cpp pick the maximum offload that fits VRAM for this model/device.
  ngl="${LLAMA_N_GPU_LAYERS:-auto}"
  fit="on"
else
  ngl="${LLAMA_N_GPU_LAYERS:-0}"
fi

extra_args=()
if [[ -n "${LLAMA_SERVER_ARGS:-}" ]]; then
  # Split on spaces intentionally for quick overrides.
  # shellcheck disable=SC2206
  extra_args=(${LLAMA_SERVER_ARGS})
fi

cmd=(
  llama-server
  --model "$model"
  --port "$port"
  --ctx-size "$ctx"
  --threads "$threads"
)

if [[ -n "$ngl" ]]; then
  cmd+=(--n-gpu-layers "$ngl")
fi

if [[ -n "$fit" ]]; then
  cmd+=(--fit "$fit")
fi

cmd+=("${extra_args[@]}")

exec "${cmd[@]}"
