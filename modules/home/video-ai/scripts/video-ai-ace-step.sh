set -euo pipefail

root="${VIDEO_AI_ROOT:-$HOME/Games/VideoAI}"
envs="${VIDEO_AI_ENVS:-$root/envs}"
cache="${VIDEO_AI_CACHE:-$root/cache}"
tmp="${VIDEO_AI_TMP:-$root/tmp}"
executable="$envs/ace-step/current/bin/acestep-api"
[[ -x "$executable" ]] || { echo 'Run: video-ai env sync ace-step' >&2; exit 1; }

export HF_HOME="$cache/huggingface"
export HUGGINGFACE_HUB_CACHE="$cache/huggingface/hub"
export TORCH_HOME="$cache/torch"
export TRITON_CACHE_DIR="$cache/triton/ace-step"
export TORCHINDUCTOR_CACHE_DIR="$cache/torchinductor/ace-step"
export CUDA_CACHE_PATH="$cache/cuda/ace-step"
export XDG_CACHE_HOME="$cache/xdg/ace-step"
export TMPDIR="$tmp/ace-step"
export ACESTEP_CHECKPOINTS_DIR="${VIDEO_AI_MODELS:-$HOME/Games/Models/VideoAI}/ace-step"
export ACESTEP_API_HOST="${ACESTEP_API_HOST:-127.0.0.1}"
export ACESTEP_API_PORT="${ACESTEP_API_PORT:-8001}"
export ACESTEP_LM_MODEL_PATH="${ACESTEP_LM_MODEL_PATH:-acestep-5Hz-lm-0.6B}"
export ACESTEP_LM_BACKEND="${ACESTEP_LM_BACKEND:-pt}"
export ACESTEP_NO_INIT="${ACESTEP_NO_INIT:-true}"
mkdir -p "$TRITON_CACHE_DIR" "$TORCHINDUCTOR_CACHE_DIR" "$CUDA_CACHE_PATH" "$XDG_CACHE_HOME" "$TMPDIR" "$ACESTEP_CHECKPOINTS_DIR"

exec "$executable" "$@"
