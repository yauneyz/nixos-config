set -euo pipefail

root="${VIDEO_AI_ROOT:-$HOME/Games/VideoAI}"
games_root="${VIDEO_AI_GAMES_ROOT:-$HOME/Games}"
apps="${VIDEO_AI_APPS:-$root/apps}"
envs="${VIDEO_AI_ENVS:-$root/envs}"
models="${VIDEO_AI_MODELS:-$HOME/Games/Models/VideoAI}"
work="${VIDEO_AI_WORK:-$root/work}"
source_dir="$apps/practical-rife/current"
python="$envs/practical-rife/current/bin/python"
model_dir="$models/rife/rife-v4.25/train_log"

usage() {
  echo 'Usage: video-ai-rife INPUT OUTPUT [MULTIPLIER] [RIFE options...]' >&2
  exit 2
}

[[ -f "$source_dir/inference_video.py" ]] || {
  echo 'Run: video-ai apps sync enhancement' >&2
  exit 1
}
[[ -x "$python" ]] || {
  echo 'Run: video-ai env sync enhancement' >&2
  exit 1
}
[[ -s "$model_dir/flownet.pkl" ]] || {
  echo 'Run: video-ai models sync enhancement' >&2
  exit 1
}

input="${1:-}"
output="${2:-}"
multiplier="${3:-2}"
[[ -n "$input" && -n "$output" ]] || usage
[[ "$multiplier" =~ ^[2-9][0-9]*$ ]] || {
  echo 'Multiplier must be an integer of at least 2.' >&2
  exit 2
}
shift "$(( $# >= 3 ? 3 : 2 ))"

[[ -f "$input" ]] || {
  echo "Input video not found: $input" >&2
  exit 1
}
input="$(realpath "$input")"
output="$(realpath -m "$output")"
case "$output/" in
  "$games_root/"*) ;;
  *)
    echo "Output must be below the Games filesystem: $games_root" >&2
    exit 1
    ;;
esac

mkdir -p "$(dirname "$output")" "$work/rife"
run_dir="$(mktemp -d "$work/rife/run.XXXXXX")"
cleanup() {
  rmdir -- "$run_dir" 2>/dev/null || true
}
trap cleanup EXIT

export PYTHONPATH="$models/rife/rife-v4.25:$source_dir${PYTHONPATH:+:$PYTHONPATH}"
export TMPDIR="$run_dir"
cd "$run_dir"
"$python" "$source_dir/inference_video.py" \
  "$@" \
  --fp16 \
  --model "$model_dir" \
  --video "$input" \
  --output "$output" \
  --multi "$multiplier"
