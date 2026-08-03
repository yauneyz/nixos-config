set -euo pipefail

root="${VIDEO_AI_ROOT:-$HOME/Games/VideoAI}"
envs="${VIDEO_AI_ENVS:-$root/envs}"
cache="${VIDEO_AI_CACHE:-$root/cache}"
tmp="${VIDEO_AI_TMP:-$root/tmp}"
python="$envs/chatterbox/current/bin/python"
[[ -x "$python" ]] || { echo 'Run: video-ai env sync chatterbox' >&2; exit 1; }

export HF_HOME="$cache/huggingface"
export HUGGINGFACE_HUB_CACHE="$cache/huggingface/hub"
export TORCH_HOME="$cache/torch"
export XDG_CACHE_HOME="$cache/xdg/chatterbox"
export TMPDIR="$tmp/chatterbox"
mkdir -p "$XDG_CACHE_HOME" "$TMPDIR"

exec "$python" "${VIDEO_AI_VOICE_SCRIPT:?VIDEO_AI_VOICE_SCRIPT is not set}" "$@"
