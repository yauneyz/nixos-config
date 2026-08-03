set -euo pipefail

root="${VIDEO_AI_ROOT:-$HOME/Games/VideoAI}"
apps="${VIDEO_AI_APPS:-$root/apps}"
envs="${VIDEO_AI_ENVS:-$root/envs}"
state="${VIDEO_AI_STATE:-$root/state}"
exports="${VIDEO_AI_EXPORTS:-$root/exports}"
cache="${VIDEO_AI_CACHE:-$root/cache}"
tmp="${VIDEO_AI_TMP:-$root/tmp}"
source_dir="$apps/wangp/current"
python="$envs/wangp/current/bin/python"

[[ -f "$source_dir/wgp.py" ]] || { echo 'Run: video-ai apps sync wangp' >&2; exit 1; }
[[ -x "$python" ]] || { echo 'Run: video-ai env sync wangp' >&2; exit 1; }

export HF_HOME="$cache/huggingface"
export HUGGINGFACE_HUB_CACHE="$cache/huggingface/hub"
export TORCH_HOME="$cache/torch"
export TRITON_CACHE_DIR="$cache/triton/wangp"
export TORCHINDUCTOR_CACHE_DIR="$cache/torchinductor/wangp"
export CUDA_CACHE_PATH="$cache/cuda/wangp"
export XDG_CACHE_HOME="$cache/xdg/wangp"
export TMPDIR="$tmp/wangp"
mkdir -p "$state/wangp/settings" "$state/wangp/config" "$exports/wangp" \
  "$TRITON_CACHE_DIR" "$TORCHINDUCTOR_CACHE_DIR" "$CUDA_CACHE_PATH" "$XDG_CACHE_HOME" "$TMPDIR"

cd "$source_dir"
exec "$python" wgp.py \
  --server-name 127.0.0.1 \
  --server-port "${WANGP_PORT:-7861}" \
  --settings "$state/wangp/settings" \
  --config "$state/wangp/config" \
  "$@"
