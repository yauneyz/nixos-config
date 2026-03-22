#!/usr/bin/env bash
set -euo pipefail

if ! command -v vllm >/dev/null 2>&1; then
	echo "vllm is not on PATH. Rebuild the desktop config after enabling the vLLM package." >&2
	exit 1
fi

models_dir="${VLLM_MODELS_DIR:-${LLAMA_MODELS_DIR:-/home/zac/Games/Models}}"
mkdir -p "$models_dir"

default_model="QuantTrio/GLM-4.7-Flash-AWQ"
model="${1:-${VLLM_MODEL:-$default_model}}"

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
gpu_memory_utilization="${VLLM_GPU_MEMORY_UTILIZATION:-0.9}"
default_max_model_len="8192"
if ((tensor_parallel_size >= 2)); then
	default_max_model_len="32768"
fi
max_model_len="${VLLM_MAX_MODEL_LEN:-$default_max_model_len}"
download_dir="${VLLM_DOWNLOAD_DIR:-${HF_HOME:-$HOME/.cache/huggingface}/hub}"
api_key="${VLLM_API_KEY:-}"
tokenizer="${VLLM_TOKENIZER:-}"
hf_config_path="${VLLM_HF_CONFIG_PATH:-}"
served_model_name="${VLLM_SERVED_MODEL_NAME:-glm-4.7-flash-awq}"
swap_space="${VLLM_SWAP_SPACE:-4}"
tool_call_parser="${VLLM_TOOL_CALL_PARSER:-glm47}"
reasoning_parser="${VLLM_REASONING_PARSER:-glm45}"
speculative_method="${VLLM_SPECULATIVE_METHOD:-mtp}"
num_speculative_tokens="${VLLM_NUM_SPECULATIVE_TOKENS:-1}"
enable_glm_defaults="${VLLM_ENABLE_GLM_DEFAULTS:-1}"
enable_expert_parallel="${VLLM_ENABLE_EXPERT_PARALLEL:-}"

export VLLM_USE_DEEP_GEMM="${VLLM_USE_DEEP_GEMM:-0}"
export VLLM_USE_FLASHINFER_MOE_FP16="${VLLM_USE_FLASHINFER_MOE_FP16:-1}"
export VLLM_USE_FLASHINFER_SAMPLER="${VLLM_USE_FLASHINFER_SAMPLER:-0}"
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-4}"

extra_args=()
if [[ -n "${VLLM_SERVE_ARGS:-}" ]]; then
	# Split on spaces intentionally for quick overrides.
	# shellcheck disable=SC2206
	extra_args=(${VLLM_SERVE_ARGS})
fi

default_args=()
if [[ "$enable_glm_defaults" != "0" ]]; then
	default_args+=(
		--swap-space "$swap_space"
		--enable-auto-tool-choice
		--tool-call-parser "$tool_call_parser"
		--reasoning-parser "$reasoning_parser"
		--trust-remote-code
		--speculative-config.method "$speculative_method"
		--speculative-config.num_speculative_tokens "$num_speculative_tokens"
	)
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

if [[ -n "$tokenizer" ]]; then
	cmd+=(--tokenizer "$tokenizer")
fi

if [[ -n "$hf_config_path" ]]; then
	cmd+=(--hf-config-path "$hf_config_path")
fi

if [[ -n "$max_model_len" ]]; then
	cmd+=(--max-model-len "$max_model_len")
fi

if [[ -n "$download_dir" ]]; then
	cmd+=(--download-dir "$download_dir")
fi

if [[ -n "$api_key" ]]; then
	cmd+=(--api-key "$api_key")
fi

cmd+=("${default_args[@]}")
cmd+=("${extra_args[@]}")

exec "${cmd[@]}"
