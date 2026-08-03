set -euo pipefail

root="${VIDEO_AI_ROOT:-$HOME/Games/VideoAI}"
envs="${VIDEO_AI_ENVS:-$root/envs}"
cache="${VIDEO_AI_CACHE:-$root/cache}"
tmp="${VIDEO_AI_TMP:-$root/tmp}"
executable="$envs/whisperx/current/bin/whisperx"
[[ -x "$executable" ]] || { echo 'Run: video-ai env sync whisperx' >&2; exit 1; }

export HF_HOME="$cache/huggingface"
export HUGGINGFACE_HUB_CACHE="$cache/huggingface/hub"
export TORCH_HOME="$cache/torch"
export XDG_CACHE_HOME="$cache/xdg/whisperx"
export TMPDIR="$tmp/whisperx"
mkdir -p "$XDG_CACHE_HOME" "$TMPDIR"

exec "$executable" "$@"
