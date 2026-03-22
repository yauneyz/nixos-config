#!/usr/bin/env bash
set -euo pipefail

models_dir="${LLAMA_MODELS_DIR:-/home/zac/Games/Models}"
mkdir -p "$models_dir"

model="${1:-${LLAMA_OMNICODER_9B_MODEL:-$models_dir/omnicoder-9b-q6_k.gguf}}"
if [[ ! -f "$model" ]]; then
  echo "Model file not found: $model" >&2
  echo "Expected Tesslate OmniCoder Q6_K GGUF at $models_dir/omnicoder-9b-q6_k.gguf" >&2
  exit 1
fi

port="${LLAMA_PORT:-11434}"
threads="${LLAMA_THREADS:-$(nproc)}"
ctx="${LLAMA_CTX_SIZE:-8192}"
batch="${LLAMA_BATCH_SIZE:-1024}"
ubatch="${LLAMA_UBATCH_SIZE:-1024}"
ngl="${LLAMA_N_GPU_LAYERS:-auto}"
fit="${LLAMA_FIT:-on}"
override_kv="${LLAMA_OVERRIDE_KV:-llama.context_length=int:${ctx}}"
alias_name="${LLAMA_ALIAS:-omnicoder-9b}"
reasoning_format="${LLAMA_REASONING_FORMAT:-none}"
reasoning_budget="${LLAMA_REASONING_BUDGET:-0}"

extra_args=()
if [[ -n "${LLAMA_SERVER_ARGS:-}" ]]; then
  # Split on spaces intentionally for quick overrides.
  # shellcheck disable=SC2206
  extra_args=(${LLAMA_SERVER_ARGS})
fi

cmd=(
  llama-server
  --model "$model"
  --alias "$alias_name"
  --host "${LLAMA_HOST:-127.0.0.1}"
  --port "$port"
  --threads "$threads"
  --ctx-size "$ctx"
  --batch-size "$batch"
  --ubatch-size "$ubatch"
  --reasoning-format "$reasoning_format"
  --reasoning-budget "$reasoning_budget"
)

if [[ -n "$override_kv" ]]; then
  cmd+=(--override-kv "$override_kv")
fi

if [[ -n "$ngl" ]]; then
  cmd+=(--n-gpu-layers "$ngl")
fi

if [[ -n "$fit" ]]; then
  cmd+=(--fit "$fit")
fi

cmd+=("${extra_args[@]}")

exec "${cmd[@]}"
