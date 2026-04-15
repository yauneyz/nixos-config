#!/usr/bin/env bash
set -euo pipefail

repo_root="${NIXOS_CONFIG_DIR:-$HOME/nixos-config}"
ml_env_script="$repo_root/modules/home/scripts/scripts/ml-env.sh"
if [[ -f "$ml_env_script" ]]; then
	ml_env_runner=(bash "$ml_env_script")
elif command -v ml-env >/dev/null 2>&1; then
	ml_env_runner=(ml-env)
else
	echo "ml-env is not on PATH. Rebuild the desktop config to install the managed ML wrapper." >&2
	exit 1
fi

models_dir="${VLLM_MODELS_DIR:-${LLAMA_MODELS_DIR:-/home/zac/Games/Models}}"
embeddings_state_root="${EMBEDDINGS_STATE_ROOT:-${VLLM_STATE_ROOT:-}}"
if [[ -z "$embeddings_state_root" ]]; then
	for candidate in /data/zac/zac "$HOME/Games"; do
		if [[ -d "$candidate" && -w "$candidate" ]]; then
			embeddings_state_root="$candidate"
			break
		fi
	done
fi
embeddings_state_root="${embeddings_state_root:-$HOME}"

default_model_id="${VLLM_EMBEDDINGS_MODEL_ID:-Qwen/Qwen3-Embedding-0.6B}"
default_model_dir="$models_dir/Qwen3-Embedding-0.6B"
default_model="$default_model_id"
if [[ -d "$default_model_dir" ]]; then
	default_model="$default_model_dir"
fi

model="${1:-$default_model}"

export ML_UV_REQUIREMENTS_FILE="${ML_UV_REQUIREMENTS_FILE:-$repo_root/modules/home/scripts/requirements/embeddings-python.txt}"
export ML_UV_ENV_DIR="${ML_UV_ENV_DIR:-$embeddings_state_root/.local/share/nixos-embeddings-cpu}"
export ML_UV_TORCH_BACKEND="${ML_UV_TORCH_BACKEND:-cpu}"
export UV_CACHE_DIR="${UV_CACHE_DIR:-$embeddings_state_root/.cache/uv}"
export HF_HOME="${HF_HOME:-$models_dir/huggingface}"
export VLLM_PORT="${VLLM_PORT:-11435}"
export VLLM_HOST="${VLLM_HOST:-127.0.0.1}"
export VLLM_SERVED_MODEL_NAME="${VLLM_SERVED_MODEL_NAME:-${EMBEDDINGS_MODEL:-qwen3-embedding-0.6b}}"
export VLLM_MAX_MODEL_LEN="${VLLM_MAX_MODEL_LEN:-8192}"
export VLLM_MAX_NUM_SEQS="${VLLM_MAX_NUM_SEQS:-32}"
export VLLM_DTYPE="${VLLM_DTYPE:-float32}"
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-4}"
export TOKENIZERS_PARALLELISM="${TOKENIZERS_PARALLELISM:-false}"

mkdir -p "$models_dir" "$HF_HOME" "$UV_CACHE_DIR" "$(dirname "$ML_UV_ENV_DIR")"

exec "${ml_env_runner[@]}" python "$repo_root/modules/home/scripts/scripts/openai-embeddings-cpu-server.py" "$model"
