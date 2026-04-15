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

export ML_UV_REQUIREMENTS_FILE="${ML_UV_REQUIREMENTS_FILE:-$repo_root/modules/home/scripts/requirements/ml-python.txt}"

models_dir="${VLLM_MODELS_DIR:-${LLAMA_MODELS_DIR:-/home/zac/Games/Models}}"
vllm_state_root="${VLLM_STATE_ROOT:-}"
if [[ -z "$vllm_state_root" ]]; then
	for candidate in /data/zac/zac "$HOME/Games"; do
		if [[ -d "$candidate" && -w "$candidate" ]]; then
			vllm_state_root="$candidate"
			break
		fi
	done
fi
vllm_state_root="${vllm_state_root:-$HOME}"

export ML_UV_ENV_DIR="${ML_UV_ENV_DIR:-$vllm_state_root/.local/share/nixos-vllm}"
export UV_CACHE_DIR="${UV_CACHE_DIR:-$vllm_state_root/.cache/uv}"
export HF_HOME="${HF_HOME:-$models_dir/huggingface}"

mkdir -p "$models_dir" "$HF_HOME" "$UV_CACHE_DIR" "$(dirname "$ML_UV_ENV_DIR")"

default_model_id="Qwen/Qwen3-14B-AWQ"
default_model_dir="$models_dir/Qwen3-14B-AWQ"
default_model="$default_model_id"
if [[ -d "$default_model_dir" ]]; then
	default_model="$default_model_dir"
fi
model="${1:-${VLLM_MODEL:-$default_model}}"
model_hint="${model##*/}"

if [[ -e "$model" ]]; then
	if [[ -f "$model" ]]; then
		model_file="$(basename "$model")"
		if [[ ! "$model_file" =~ \.gguf$ ]]; then
			echo "Local file models must be .gguf for vLLM: $model" >&2
			exit 1
		fi

		if [[ "$model_file" =~ -[0-9]{5}-of-[0-9]{5}\.gguf$ ]]; then
			cat >&2 <<EOF
Split GGUF shards are not supported by this vLLM wrapper: $model
Use a single-file GGUF, a HuggingFace model directory, or a remote model ID instead.
EOF
			exit 1
		fi

		if [[ -z "${VLLM_TOKENIZER:-}" ]]; then
			echo "Serving GGUF without VLLM_TOKENIZER; set it if the model needs an explicit tokenizer." >&2
		fi
	elif [[ ! -d "$model" ]]; then
		echo "Model path must be a directory or a .gguf file: $model" >&2
		exit 1
	fi
fi

gpu_count=0
if command -v nvidia-smi >/dev/null 2>&1; then
	gpu_count="$(nvidia-smi -L 2>/dev/null | wc -l | tr -d '[:space:]')"
fi

default_tensor_parallel_size=1
if [[ "$gpu_count" =~ ^[0-9]+$ ]] && ((gpu_count >= 2)); then
	default_tensor_parallel_size=2
fi

host="${VLLM_HOST:-127.0.0.1}"
port="${VLLM_PORT:-${LLAMA_PORT:-11434}}"
dtype="${VLLM_DTYPE:-auto}"
tensor_parallel_size="${VLLM_TENSOR_PARALLEL_SIZE:-$default_tensor_parallel_size}"
default_gpu_memory_utilization="0.9"
default_gpu_memory_headroom_mib="0"
default_max_model_len="8192"
default_enforce_eager="0"
default_max_num_seqs=""
if (( tensor_parallel_size == 1 )); then
	default_gpu_memory_utilization="0.82"
	default_gpu_memory_headroom_mib="2048"
	default_enforce_eager="1"
	default_max_model_len="2048"
	default_max_num_seqs="32"
	if [[ "$model_hint" == "Qwen3-14B-AWQ" ]]; then
		default_max_model_len="32768"
		default_max_num_seqs="8"
	fi
fi
gpu_memory_utilization="${VLLM_GPU_MEMORY_UTILIZATION:-}"
gpu_memory_headroom_mib="${VLLM_GPU_MEMORY_HEADROOM_MIB:-$default_gpu_memory_headroom_mib}"
if [[ -z "$gpu_memory_utilization" ]]; then
	gpu_memory_utilization="$default_gpu_memory_utilization"
	if command -v nvidia-smi >/dev/null 2>&1 &&
		[[ "$gpu_memory_headroom_mib" =~ ^[0-9]+$ ]] &&
		(( gpu_memory_headroom_mib > 0 )); then
		auto_gpu_memory_utilization=""
		while IFS=',' read -r raw_total_mib raw_free_mib; do
			total_mib="${raw_total_mib//[!0-9]/}"
			free_mib="${raw_free_mib//[!0-9]/}"
			if [[ ! "$total_mib" =~ ^[0-9]+$ || ! "$free_mib" =~ ^[0-9]+$ ]] ||
				(( total_mib == 0 || free_mib <= gpu_memory_headroom_mib )); then
				continue
			fi

			candidate_gpu_memory_utilization="$(
				awk -v free="$free_mib" -v total="$total_mib" -v headroom="$gpu_memory_headroom_mib" \
					'BEGIN { printf "%.4f", (free - headroom) / total }'
			)"
			if [[ -z "$auto_gpu_memory_utilization" ]] ||
				awk -v candidate="$candidate_gpu_memory_utilization" -v current="$auto_gpu_memory_utilization" \
					'BEGIN { exit !(candidate < current) }'; then
				auto_gpu_memory_utilization="$candidate_gpu_memory_utilization"
			fi
		done < <(nvidia-smi --query-gpu=memory.total,memory.free --format=csv,noheader,nounits 2>/dev/null || true)

		if [[ -n "$auto_gpu_memory_utilization" ]] &&
			awk -v auto="$auto_gpu_memory_utilization" -v baseline="$default_gpu_memory_utilization" \
				'BEGIN { exit !(auto < baseline) }'; then
			echo "Lowering VLLM GPU memory utilization to $auto_gpu_memory_utilization to keep ${gpu_memory_headroom_mib} MiB free at startup." >&2
			gpu_memory_utilization="$auto_gpu_memory_utilization"
		fi
	fi
fi
if ((tensor_parallel_size >= 2)); then
	default_max_model_len="32768"
fi
max_model_len="${VLLM_MAX_MODEL_LEN:-$default_max_model_len}"
enforce_eager="${VLLM_ENFORCE_EAGER:-$default_enforce_eager}"
max_num_seqs="${VLLM_MAX_NUM_SEQS:-$default_max_num_seqs}"
download_dir="${VLLM_DOWNLOAD_DIR:-$HF_HOME/hub}"
api_key="${VLLM_API_KEY:-}"
tokenizer="${VLLM_TOKENIZER:-}"
hf_config_path="${VLLM_HF_CONFIG_PATH:-}"
runner="${VLLM_RUNNER:-}"
convert="${VLLM_CONVERT:-}"
served_model_name="${VLLM_SERVED_MODEL_NAME:-qwen3-14b-awq}"
reasoning_parser="${VLLM_REASONING_PARSER:-qwen3}"
enable_qwen_defaults="${VLLM_ENABLE_QWEN_DEFAULTS:-1}"
enable_expert_parallel="${VLLM_ENABLE_EXPERT_PARALLEL:-}"

export OMP_NUM_THREADS="${OMP_NUM_THREADS:-4}"

extra_args=()
if [[ -n "${VLLM_SERVE_ARGS:-}" ]]; then
	# Split on spaces intentionally for quick overrides.
	# shellcheck disable=SC2206
	extra_args=(${VLLM_SERVE_ARGS})
fi

default_args=()
if [[ "$enable_qwen_defaults" != "0" ]]; then
	if [[ -n "$reasoning_parser" ]]; then
		default_args+=(--reasoning-parser "$reasoning_parser")
	fi
fi

cmd=(
	vllm
	serve
	"$model"
	--host "$host"
	--port "$port"
	--dtype "$dtype"
	--served-model-name "$served_model_name"
	--tensor-parallel-size "$tensor_parallel_size"
	--gpu-memory-utilization "$gpu_memory_utilization"
)

if [[ -n "$runner" ]]; then
	cmd+=(--runner "$runner")
fi

if [[ -n "$convert" ]]; then
	cmd+=(--convert "$convert")
fi

if [[ -z "$enable_expert_parallel" ]]; then
	if ((tensor_parallel_size >= 2)); then
		enable_expert_parallel="1"
	else
		enable_expert_parallel="0"
	fi
fi

if [[ "$enable_expert_parallel" != "0" ]]; then
	cmd+=(--enable-expert-parallel)
fi

if [[ "$enforce_eager" != "0" ]]; then
	cmd+=(--enforce-eager)
fi

if [[ -n "$tokenizer" ]]; then
	cmd+=(--tokenizer "$tokenizer")
fi

if [[ -n "$hf_config_path" ]]; then
	cmd+=(--hf-config-path "$hf_config_path")
fi

if [[ -n "$max_model_len" ]]; then
	cmd+=(--max-model-len "$max_model_len")
fi

if [[ -n "$max_num_seqs" ]]; then
	cmd+=(--max-num-seqs "$max_num_seqs")
fi

if [[ -n "$download_dir" ]]; then
	cmd+=(--download-dir "$download_dir")
fi

if [[ -n "$api_key" ]]; then
	cmd+=(--api-key "$api_key")
fi

cmd+=("${default_args[@]}")
cmd+=("${extra_args[@]}")

exec "${ml_env_runner[@]}" run "${cmd[@]}"
