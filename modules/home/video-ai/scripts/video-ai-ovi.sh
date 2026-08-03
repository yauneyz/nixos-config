set -euo pipefail

root="${VIDEO_AI_ROOT:-$HOME/Games/VideoAI}"
apps="${VIDEO_AI_APPS:-$root/apps}"
envs="${VIDEO_AI_ENVS:-$root/envs}"
models="${VIDEO_AI_MODELS:-$HOME/Games/Models/VideoAI}"
exports="${VIDEO_AI_EXPORTS:-$root/exports}"
cache="${VIDEO_AI_CACHE:-$root/cache}"
tmp="${VIDEO_AI_TMP:-$root/tmp}"
source_dir="$apps/ovi/current"
python="$envs/ovi/current/bin/python"

[[ -f "$source_dir/gradio_app.py" ]] || { echo 'Run: video-ai apps sync ovi' >&2; exit 1; }
[[ -x "$python" ]] || { echo 'Run: video-ai env sync ovi' >&2; exit 1; }
"$python" -c 'import flash_attn' 2>/dev/null || {
  echo 'Standalone Ovi requires FlashAttention; run video-ai doctor for status.' >&2
  exit 1
}

for managed_path in ckpts outputs; do
  if [[ -e "$source_dir/$managed_path" && ! -L "$source_dir/$managed_path" ]]; then
    echo "Refusing to replace unmanaged path: $source_dir/$managed_path" >&2
    exit 1
  fi
done
ln -sfn "$models/ovi" "$source_dir/ckpts"
ln -sfn "$exports/ovi" "$source_dir/outputs"

export HF_HOME="$cache/huggingface"
export HUGGINGFACE_HUB_CACHE="$cache/huggingface/hub"
export TORCH_HOME="$cache/torch"
export TRITON_CACHE_DIR="$cache/triton/ovi"
export CUDA_CACHE_PATH="$cache/cuda/ovi"
export XDG_CACHE_HOME="$cache/xdg/ovi"
export TMPDIR="$tmp/ovi"
mkdir -p "$TRITON_CACHE_DIR" "$CUDA_CACHE_PATH" "$XDG_CACHE_HOME" "$TMPDIR" "$exports/ovi"

cd "$source_dir"
exec "$python" gradio_app.py --cpu_offload --fp8 "$@"
