#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<'EOF'
Usage: textgen-serve [textgen server flags...]

Installs oobabooga/textgen on first run and launches its browser UI.

Useful environment overrides:
  TEXTGEN_DIR            Textgen checkout/install directory
  TEXTGEN_USER_DATA_DIR  Textgen user_data directory
  TEXTGEN_MODELS_DIR     Model directory exposed to textgen
  TEXTGEN_HOST           Gradio host, default 127.0.0.1
  TEXTGEN_PORT           Gradio port, default 7860
  TEXTGEN_API_PORT       OpenAI/Anthropic-compatible API port, default 5000
  TEXTGEN_GPU_CHOICE     Upstream installer GPU choice: A, B, C, D, or N
  TEXTGEN_ARGS           Extra flags split on spaces before argv
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "${1:-}" == "help" ]]; then
	usage
	exit 0
fi

require_command() {
	local cmd="$1"
	if ! command -v "$cmd" >/dev/null 2>&1; then
		echo "Required command not found: $cmd" >&2
		exit 1
	fi
}

data_home="${ZAC_DATA_HOME:-$HOME}"
# Models live on the Games partition under the login home ($HOME/Games), not on
# the data partition ($data_home). LLAMA_MODELS_DIR already resolves there.
models_root="${LLAMA_MODELS_DIR:-$HOME/Games/Models}"
textgen_dir="${TEXTGEN_DIR:-$data_home/Games/LLM/textgen}"
user_data_dir="${TEXTGEN_USER_DATA_DIR:-$data_home/Games/LLM/textgen-user-data}"
models_dir="${TEXTGEN_MODELS_DIR:-$models_root}"
host="${TEXTGEN_HOST:-127.0.0.1}"
port="${TEXTGEN_PORT:-7860}"
api_port="${TEXTGEN_API_PORT:-5000}"

require_command git
require_command curl

mkdir -p "$(dirname "$textgen_dir")" "$user_data_dir" "$models_dir"

if [[ ! -d "$textgen_dir" ]]; then
	echo "Installing textgen into $textgen_dir" >&2
	git clone https://github.com/oobabooga/textgen "$textgen_dir"
	(
		cd "$textgen_dir"
		latest_tag="$(git tag -l 'v*' --sort=-v:refname | head -n 1 || true)"
		if [[ -n "$latest_tag" ]]; then
			git checkout "$latest_tag"
		fi
	)
fi

if [[ ! -f "$textgen_dir/start_linux.sh" ]]; then
	cat >&2 <<EOF
Textgen checkout is missing start_linux.sh: $textgen_dir
Delete the directory and rerun this command, or set TEXTGEN_DIR to a valid textgen checkout.
EOF
	exit 1
fi

# Textgen ships a user_data template (characters, presets, instruction-templates,
# grammars, ...) inside its checkout, but pointing --user-data-dir at an external
# directory does not seed those. The UI crashes listing e.g. characters if they
# are missing, so mirror any missing template entries without clobbering edits.
if [[ -d "$textgen_dir/user_data" && "$user_data_dir" != "$textgen_dir/user_data" ]]; then
	shopt -s nullglob dotglob
	for template_entry in "$textgen_dir"/user_data/*; do
		dest="$user_data_dir/$(basename "$template_entry")"
		if [[ ! -e "$dest" ]]; then
			cp -r "$template_entry" "$dest"
		fi
	done
	shopt -u nullglob dotglob
fi

if [[ -z "${GPU_CHOICE:-}" ]]; then
	if [[ -n "${TEXTGEN_GPU_CHOICE:-}" ]]; then
		export GPU_CHOICE="$TEXTGEN_GPU_CHOICE"
	elif command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
		export GPU_CHOICE="A"
	else
		export GPU_CHOICE="N"
	fi
fi

export HF_HOME="${HF_HOME:-$models_root/huggingface}"
export PYTHONNOUSERSITE=1
unset PYTHONPATH
unset PYTHONHOME
mkdir -p "$HF_HOME"

# The first-run installer downloads multi-GB pip wheels (torch, llama-cpp,
# ik-llama, ...). The default pip cache (~/.cache/pip) and TMPDIR live on the
# small root filesystem, which fills up mid-install. Park both alongside the
# textgen checkout (typically on a roomier data volume) so installs complete.
export PIP_CACHE_DIR="${PIP_CACHE_DIR:-$data_home/.cache/pip}"
export TMPDIR="${TMPDIR:-$data_home/tmp}"
mkdir -p "$PIP_CACHE_DIR" "$TMPDIR"

library_paths=()
if [[ -n "${NIX_LD_LIBRARY_PATH:-}" ]]; then
	library_paths+=("$NIX_LD_LIBRARY_PATH")
fi
if [[ -d /run/opengl-driver/lib ]]; then
	library_paths+=("/run/opengl-driver/lib")
	export TRITON_LIBCUDA_PATH="${TRITON_LIBCUDA_PATH:-/run/opengl-driver/lib}"
fi
if [[ -d /run/opengl-driver-32/lib ]]; then
	library_paths+=("/run/opengl-driver-32/lib")
fi
shopt -s nullglob
for library_dir in \
	"$textgen_dir"/installer_files/env/lib \
	"$textgen_dir"/installer_files/env/lib/python*/site-packages/torch/lib \
	"$textgen_dir"/installer_files/env/lib/python*/site-packages/nvidia/*/lib; do
	library_paths+=("$library_dir")
done
shopt -u nullglob
if [[ -n "${LD_LIBRARY_PATH:-}" ]]; then
	library_paths+=("$LD_LIBRARY_PATH")
fi
if ((${#library_paths[@]} > 0)); then
	old_ifs="$IFS"
	IFS=:
	export LD_LIBRARY_PATH="${library_paths[*]}"
	IFS="$old_ifs"
fi

cmd=(
	./start_linux.sh
	--user-data-dir "$user_data_dir"
	--model-dir "$models_dir"
	--listen-host "$host"
	--listen-port "$port"
	--api
	--api-port "$api_port"
)

if [[ -n "${TEXTGEN_MODEL:-}" ]]; then
	cmd+=(--model "$TEXTGEN_MODEL")
fi
if [[ -n "${TEXTGEN_LOADER:-}" ]]; then
	cmd+=(--loader "$TEXTGEN_LOADER")
fi
if [[ -n "${TEXTGEN_CTX_SIZE:-}" ]]; then
	cmd+=(--ctx-size "$TEXTGEN_CTX_SIZE")
fi
if [[ -n "${TEXTGEN_GPU_LAYERS:-}" ]]; then
	cmd+=(--gpu-layers "$TEXTGEN_GPU_LAYERS")
fi
if [[ -n "${TEXTGEN_API_KEY:-}" ]]; then
	cmd+=(--api-key "$TEXTGEN_API_KEY")
fi
if [[ -n "${TEXTGEN_ADMIN_KEY:-}" ]]; then
	cmd+=(--admin-key "$TEXTGEN_ADMIN_KEY")
fi
if [[ -n "${TEXTGEN_GRADIO_AUTH:-}" ]]; then
	cmd+=(--gradio-auth "$TEXTGEN_GRADIO_AUTH")
fi
if [[ "${TEXTGEN_LISTEN:-0}" != "0" ]]; then
	cmd+=(--listen)
fi
if [[ "${TEXTGEN_AUTO_LAUNCH:-0}" != "0" ]]; then
	cmd+=(--auto-launch)
fi
if [[ -n "${TEXTGEN_ARGS:-}" ]]; then
	# Split on spaces intentionally for quick one-off overrides.
	# shellcheck disable=SC2206
	extra_args=(${TEXTGEN_ARGS})
	cmd+=("${extra_args[@]}")
fi

cmd+=("$@")

cd "$textgen_dir"
exec "${cmd[@]}"
