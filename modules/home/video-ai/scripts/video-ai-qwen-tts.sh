set -euo pipefail

root="${VIDEO_AI_ROOT:-$HOME/Games/VideoAI}"
envs="${VIDEO_AI_ENVS:-$root/envs}"
cache="${VIDEO_AI_CACHE:-$root/cache}"
tmp="${VIDEO_AI_TMP:-$root/tmp}"
executable="$envs/qwen-tts/current/bin/qwen-tts-demo"
[[ -x "$executable" ]] || { echo 'Run: video-ai env sync qwen-tts' >&2; exit 1; }

# First positional argument selects the checkpoint; the rest pass through to
# qwen-tts-demo. Weights are fetched from the Hugging Face Hub on first use.
#   Qwen/Qwen3-TTS-12Hz-1.7B-CustomVoice  preset speakers + style instructions
#   Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign  voice designed from a text description
#   Qwen/Qwen3-TTS-12Hz-1.7B-Base         3-second reference-audio voice cloning
model="Qwen/Qwen3-TTS-12Hz-1.7B-CustomVoice"
if [[ $# -gt 0 && "$1" != -* ]]; then
  model="$1"
  shift
fi

export HF_HOME="$cache/huggingface"
export HUGGINGFACE_HUB_CACHE="$cache/huggingface/hub"
export TORCH_HOME="$cache/torch"
export XDG_CACHE_HOME="$cache/xdg/qwen-tts"
export GRADIO_TEMP_DIR="$tmp/qwen-tts/gradio"
export TMPDIR="$tmp/qwen-tts"
mkdir -p "$XDG_CACHE_HOME" "$GRADIO_TEMP_DIR" "$TMPDIR"

flash_flag=--no-flash-attn
"$envs/qwen-tts/current/bin/python" -c 'import flash_attn' 2>/dev/null && flash_flag=--flash-attn

# Upstream defaults to 0.0.0.0; keep it on loopback like every other service.
exec "$executable" "$model" \
  --ip 127.0.0.1 \
  --port "${QWEN_TTS_PORT:-7862}" \
  "$flash_flag" \
  "$@"
