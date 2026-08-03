set -euo pipefail

root="${VIDEO_AI_ROOT:-$HOME/Games/VideoAI}"
apps="${VIDEO_AI_APPS:-$root/apps}"
envs="${VIDEO_AI_ENVS:-$root/envs}"
state="${VIDEO_AI_STATE:-$root/state}"
work="${VIDEO_AI_WORK:-$root/work}"
exports="${VIDEO_AI_EXPORTS:-$root/exports}"
tmp="${VIDEO_AI_TMP:-$root/tmp}"
cache="${VIDEO_AI_CACHE:-$root/cache}"

source_dir="$apps/comfyui/current"
python="$envs/comfyui/current/bin/python"
[[ -f "$source_dir/main.py" ]] || { echo 'Run: video-ai apps sync core' >&2; exit 1; }
[[ -x "$python" ]] || { echo 'Run: video-ai env sync core' >&2; exit 1; }

export HF_HOME="$cache/huggingface"
export HUGGINGFACE_HUB_CACHE="$cache/huggingface/hub"
export TORCH_HOME="$cache/torch"
export TRITON_CACHE_DIR="$cache/triton/comfyui"
export TORCHINDUCTOR_CACHE_DIR="$cache/torchinductor/comfyui"
export CUDA_CACHE_PATH="$cache/cuda/comfyui"
export XDG_CACHE_HOME="$cache/xdg/comfyui"
export TMPDIR="$tmp/comfyui"
mkdir -p "$TRITON_CACHE_DIR" "$TORCHINDUCTOR_CACHE_DIR" "$CUDA_CACHE_PATH" "$XDG_CACHE_HOME" "$TMPDIR"

exec "$python" "$source_dir/main.py" \
  --listen 127.0.0.1 \
  --port "${COMFYUI_PORT:-8188}" \
  --base-directory "$state/comfyui" \
  --models-directory "${VIDEO_AI_MODELS:-$HOME/Games/Models/VideoAI}/comfy" \
  --extra-model-paths-config "${VIDEO_AI_COMFY_MODEL_PATHS:?VIDEO_AI_COMFY_MODEL_PATHS is not set}" \
  --input-directory "$state/comfyui/input" \
  --output-directory "$exports/comfyui" \
  --temp-directory "$work/comfyui" \
  --user-directory "$state/comfyui/user" \
  --database-url "sqlite:///$state/comfyui/user/comfyui.db" \
  "$@"
