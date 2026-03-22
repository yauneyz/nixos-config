#!/usr/bin/env bash
set -euo pipefail

models_dir="${LLAMA_MODELS_DIR:-/home/zac/Games/Models}"
mkdir -p "$models_dir"

model="${1:-${LLAMA_GPT_OSS_20B_MODEL:-$models_dir/gpt-oss-20b-Q6_K.gguf}}"
if [[ ! -f "$model" ]]; then
  echo "Model file not found: $model" >&2
  echo "Expected ggml-org gpt-oss-20b GGUF at $models_dir/gpt-oss-20b-Q6_K.gguf" >&2
  exit 1
fi

port="${LLAMA_PORT:-11434}"
threads="${LLAMA_THREADS:-$(nproc)}"
ctx="${LLAMA_CTX_SIZE:-8192}"
batch="${LLAMA_BATCH_SIZE:-1024}"
ubatch="${LLAMA_UBATCH_SIZE:-1024}"
reasoning_format="${LLAMA_REASONING_FORMAT:-none}"
reasoning_budget="${LLAMA_REASONING_BUDGET:-0}"
flash_attn="${LLAMA_FLASH_ATTN:-auto}"
ngl="${LLAMA_N_GPU_LAYERS:-auto}"
fit="${LLAMA_FIT:-on}"
n_cpu_moe="${LLAMA_N_CPU_MOE:-}"
override_kv="${LLAMA_OVERRIDE_KV:-llama.context_length=int:${ctx}}"
alias_name="${LLAMA_ALIAS:-gpt-oss-20b}"
temp="${LLAMA_TEMPERATURE:-1.0}"
top_p="${LLAMA_TOP_P:-1.0}"
top_k="${LLAMA_TOP_K:-0}"
min_p="${LLAMA_MIN_P:-0.0}"
repeat_penalty="${LLAMA_REPEAT_PENALTY:-1.0}"
presence_penalty="${LLAMA_PRESENCE_PENALTY:-0.0}"
frequency_penalty="${LLAMA_FREQUENCY_PENALTY:-0.0}"
dry_multiplier="${LLAMA_DRY_MULTIPLIER:-0.0}"

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
  --jinja
  --reasoning-format "$reasoning_format"
  --reasoning-budget "$reasoning_budget"
  --flash-attn "$flash_attn"
  --temp "$temp"
  --top-p "$top_p"
  --top-k "$top_k"
  --min-p "$min_p"
  --repeat-penalty "$repeat_penalty"
  --presence-penalty "$presence_penalty"
  --frequency-penalty "$frequency_penalty"
  --dry-multiplier "$dry_multiplier"
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

if [[ -n "$n_cpu_moe" ]]; then
  cmd+=(--n-cpu-moe "$n_cpu_moe")
fi

cmd+=("${extra_args[@]}")

exec "${cmd[@]}"
