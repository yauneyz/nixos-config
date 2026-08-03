set -euo pipefail

video_ai_root="${VIDEO_AI_ROOT:-$HOME/Games/VideoAI}"
games_root="${VIDEO_AI_GAMES_ROOT:-$HOME/Games}"
models_root="${VIDEO_AI_MODELS:-$HOME/Games/Models/VideoAI}"
apps_root="${VIDEO_AI_APPS:-$video_ai_root/apps}"
envs_root="${VIDEO_AI_ENVS:-$video_ai_root/envs}"
cache_root="${VIDEO_AI_CACHE:-$video_ai_root/cache}"
state_root="${VIDEO_AI_STATE:-$video_ai_root/state}"
projects_root="${VIDEO_AI_PROJECTS:-$video_ai_root/projects}"
work_root="${VIDEO_AI_WORK:-$video_ai_root/work}"
exports_root="${VIDEO_AI_EXPORTS:-$video_ai_root/exports}"
tmp_root="${VIDEO_AI_TMP:-$video_ai_root/tmp}"
apps_manifest="${VIDEO_AI_APPS_MANIFEST:?VIDEO_AI_APPS_MANIFEST is not set}"
models_manifest="${VIDEO_AI_MODELS_MANIFEST:?VIDEO_AI_MODELS_MANIFEST is not set}"
workflows_manifest="${VIDEO_AI_WORKFLOWS_MANIFEST:?VIDEO_AI_WORKFLOWS_MANIFEST is not set}"
python_cmd="${VIDEO_AI_PYTHON:-python3.11}"
reserve_gib="${VIDEO_AI_MIN_FREE_GIB:-100}"

die() {
  printf 'video-ai: %s\n' "$*" >&2
  exit 1
}

note() {
  printf 'video-ai: %s\n' "$*"
}

require_safe_paths() {
  local mount_target
  case "$video_ai_root/" in
    "$games_root/"*) ;;
    *) die "VIDEO_AI_ROOT must be below $games_root (got $video_ai_root)" ;;
  esac
  case "$models_root/" in
    "$games_root/"*) ;;
    *) die "VIDEO_AI_MODELS must be below $games_root (got $models_root)" ;;
  esac

  [[ -d "$games_root" ]] || die "Games root does not exist: $games_root"
  mount_target="$(findmnt -n -o TARGET -T "$games_root")"
  [[ "$mount_target" == "$games_root" ]] ||
    die "$games_root is not its own mounted filesystem (resolved mount: $mount_target)"
}

init_layout() {
  require_safe_paths
  mkdir -p \
    "$apps_root" \
    "$envs_root" \
    "$cache_root/huggingface" \
    "$cache_root/torch" \
    "$cache_root/triton" \
    "$cache_root/uv" \
    "$state_root/comfyui/custom_nodes" \
    "$state_root/comfyui/input" \
    "$state_root/comfyui/user" \
    "$state_root/wangp" \
    "$state_root/ace-step" \
    "$projects_root" \
    "$work_root/comfyui" \
    "$exports_root/comfyui" \
    "$exports_root/wangp" \
    "$exports_root/ovi" \
    "$tmp_root" \
    "$models_root/comfy/checkpoints" \
    "$models_root/comfy/clip_vision" \
    "$models_root/comfy/controlnet" \
    "$models_root/comfy/diffusion_models" \
    "$models_root/comfy/loras" \
    "$models_root/comfy/mmaudio" \
    "$models_root/comfy/text_encoders" \
    "$models_root/comfy/upscale_models" \
    "$models_root/comfy/vae" \
    "$models_root/ace-step" \
    "$models_root/chatterbox" \
    "$models_root/ovi" \
    "$models_root/wangp" \
    "$models_root/whisperx"
  chmod 700 "$state_root" "$projects_root"
}

manifest_app_field() {
  local name="$1"
  local field="$2"
  jq -er --arg name "$name" --arg field "$field" \
    '.[] | select(.name == $name) | .[$field]' "$apps_manifest"
}

app_current() {
  local name="$1"
  local current="$apps_root/$name/current"
  [[ -d "$current" ]] || die "$name is not synced; run: video-ai apps sync $name"
  printf '%s\n' "$current"
}

link_managed_nodes() {
  local wrapper="$apps_root/wan-video-wrapper/current"
  if [[ -d "$wrapper" ]]; then
    ln -sfn "$wrapper" "$state_root/comfyui/custom_nodes/ComfyUI-WanVideoWrapper"
  fi
}

app_matches_selector() {
  local name="$1"
  local profile="$2"
  local selector="$3"
  [[ "$selector" == "all" || "$selector" == "$name" || "$selector" == "$profile" ]]
}

sync_apps() {
  local selector="${1:-core}"
  local matched=0
  local name profile url revision license target current actual partial
  init_layout

  while IFS=$'\t' read -r name profile url revision license; do
    app_matches_selector "$name" "$profile" "$selector" || continue
    matched=1
    target="$apps_root/$name/$revision"
    current="$apps_root/$name/current"
    mkdir -p "$apps_root/$name"

    if [[ -d "$target/.git" ]]; then
      actual="$(git -C "$target" rev-parse HEAD)"
      [[ "$actual" == "$revision" ]] ||
        die "$target exists at unexpected revision $actual"
      note "$name source already present ($revision)"
    else
      partial="$target.partial.$$"
      [[ ! -e "$partial" ]] || die "temporary source path already exists: $partial"
      note "cloning $name at $revision"
      git clone --filter=blob:none --no-checkout "$url" "$partial"
      git -C "$partial" checkout --detach "$revision"
      mv "$partial" "$target"
    fi

    ln -sfn "$target" "$current.next"
    mv -Tf "$current.next" "$current"
    printf '%s\t%s\t%s\n' "$name" "$revision" "$license"
  done < <(jq -r '.[] | [.name, .profile, .url, .revision, .license] | @tsv' "$apps_manifest")

  [[ "$matched" == 1 ]] || die "unknown app or profile: $selector"
  link_managed_nodes
}

env_key() {
  local name="$1"
  local revision
  local wrapper_revision
  revision="$(manifest_app_field "$name" revision)"
  case "$name" in
    comfyui)
      wrapper_revision="$(manifest_app_field wan-video-wrapper revision)"
      printf '%s-%s-cu130-v1\n' "${revision:0:12}" "${wrapper_revision:0:12}"
      ;;
    ace-step)
      printf '%s-reloc-v2\n' "${revision:0:12}"
      ;;
    whisperx)
      printf '%s-py311-reloc-v3\n' "${revision:0:12}"
      ;;
    practical-rife)
      printf '%s-cu130-reloc-v1\n' "${revision:0:12}"
      ;;
    *) printf '%s-v1\n' "${revision:0:12}" ;;
  esac
}

env_current() {
  local name="$1"
  local current="$envs_root/$name/current"
  [[ -x "$current/bin/python" ]] || die "$name environment is not synced; run: video-ai env sync $name"
  printf '%s\n' "$current"
}

prepare_env() {
  local name="$1"
  local key="$2"
  local target="$envs_root/$name/$key"
  if [[ -x "$target/bin/python" && -f "$target/.video-ai-complete" ]]; then
    printf '%s\n' "$target"
    return 1
  fi

  local partial="$target.partial.$$"
  mkdir -p "$envs_root/$name"
  [[ ! -e "$partial" ]] || die "temporary environment path already exists: $partial"
  uv venv --python "$python_cmd" --seed --relocatable "$partial"
  printf '%s\n' "$partial"
}

finish_env() {
  local name="$1"
  local key="$2"
  local partial="$3"
  local target="$envs_root/$name/$key"
  local current="$envs_root/$name/current"
  touch "$partial/.video-ai-complete"
  mv "$partial" "$target"
  ln -sfn "$target" "$current.next"
  mv -Tf "$current.next" "$current"
  note "$name environment ready: $target"
}

sync_comfy_env() {
  sync_apps comfyui
  sync_apps wan-video-wrapper
  local key target_or_partial
  key="$(env_key comfyui)"
  if ! target_or_partial="$(prepare_env comfyui "$key")"; then
    note "comfyui environment already present: $target_or_partial"
    return
  fi
  local comfy wrapper
  comfy="$(app_current comfyui)"
  wrapper="$(app_current wan-video-wrapper)"

  uv pip install --python "$target_or_partial/bin/python" \
    --index-strategy unsafe-best-match \
    --extra-index-url https://download.pytorch.org/whl/cu130 \
    'torch==2.10.0+cu130' 'torchvision==0.25.0+cu130' 'torchaudio==2.10.0+cu130'
  uv pip install --python "$target_or_partial/bin/python" \
    --index-strategy unsafe-best-match \
    --extra-index-url https://download.pytorch.org/whl/cu130 \
    -r "$comfy/requirements.txt" -r "$wrapper/requirements.txt"
  finish_env comfyui "$key" "$target_or_partial"
}

sync_chatterbox_env() {
  sync_apps chatterbox
  local key target_or_partial source
  key="$(env_key chatterbox)"
  if ! target_or_partial="$(prepare_env chatterbox "$key")"; then
    note "chatterbox environment already present: $target_or_partial"
    return
  fi
  source="$(app_current chatterbox)"

  uv pip install --python "$target_or_partial/bin/python" \
    --index-strategy unsafe-best-match \
    --extra-index-url https://download.pytorch.org/whl/cu124 \
    'torch==2.6.0+cu124' 'torchaudio==2.6.0+cu124'
  uv pip install --python "$target_or_partial/bin/python" \
    'numpy>=1.24.0,<2.0.0' 'librosa==0.11.0' s3tokenizer \
    'transformers==5.2.0' 'diffusers==0.29.0' \
    'resemble-perth @ git+https://github.com/resemble-ai/Perth.git@ce86c49d029f42272c1902eccb675556b9ed2330' \
    'conformer==0.3.2' 'safetensors==0.5.3' spacy-pkuseg \
    'pykakasi==2.3.0' 'gradio==6.8.0' pyloudnorm omegaconf
  uv pip install --python "$target_or_partial/bin/python" --no-deps "$source"
  finish_env chatterbox "$key" "$target_or_partial"
}

sync_locked_uv_env() {
  local name="$1"
  sync_apps "$name"
  local key target_or_partial source
  key="$(env_key "$name")"
  if ! target_or_partial="$(prepare_env "$name" "$key")"; then
    note "$name environment already present: $target_or_partial"
    return
  fi
  source="$(app_current "$name")"
  UV_PROJECT_ENVIRONMENT="$target_or_partial" uv sync \
    --frozen \
    --no-dev \
    --no-python-downloads \
    --python "$python_cmd" \
    --project "$source"
  finish_env "$name" "$key" "$target_or_partial"
}

sync_wangp_env() {
  sync_apps wangp
  local key target_or_partial source
  key="$(env_key wangp)"
  if ! target_or_partial="$(prepare_env wangp "$key")"; then
    note "wangp environment already present: $target_or_partial"
    return
  fi
  source="$(app_current wangp)"
  uv pip install --python "$target_or_partial/bin/python" \
    --index-strategy unsafe-best-match \
    --extra-index-url https://download.pytorch.org/whl/cu130 \
    'torch==2.10.0+cu130' 'torchvision==0.25.0+cu130' 'torchaudio==2.10.0+cu130'
  uv pip install --python "$target_or_partial/bin/python" \
    --index-strategy unsafe-best-match \
    --extra-index-url https://download.pytorch.org/whl/cu130 \
    -r "$source/requirements.txt"
  finish_env wangp "$key" "$target_or_partial"
}

sync_rife_env() {
  sync_apps practical-rife
  local key target_or_partial
  key="$(env_key practical-rife)"
  if ! target_or_partial="$(prepare_env practical-rife "$key")"; then
    note "Practical-RIFE environment already present: $target_or_partial"
    return
  fi

  uv pip install --python "$target_or_partial/bin/python" \
    --index-strategy unsafe-best-match \
    --extra-index-url https://download.pytorch.org/whl/cu130 \
    'torch==2.10.0+cu130' 'torchvision==0.25.0+cu130'
  uv pip install --python "$target_or_partial/bin/python" \
    'numpy==1.23.5' \
    'tqdm==4.67.1' \
    'scikit-video==1.1.11' \
    'opencv-python-headless==4.11.0.86' \
    'moviepy==1.0.3' \
    'imageio-ffmpeg==0.6.0'
  finish_env practical-rife "$key" "$target_or_partial"
}

sync_ovi_env() {
  sync_apps ovi
  local key target_or_partial source
  key="$(env_key ovi)"
  if ! target_or_partial="$(prepare_env ovi "$key")"; then
    note "ovi environment already present: $target_or_partial"
    return
  fi
  source="$(app_current ovi)"
  uv pip install --python "$target_or_partial/bin/python" \
    --index-strategy unsafe-best-match \
    --extra-index-url https://download.pytorch.org/whl/cu124 \
    'torch==2.6.0+cu124' 'torchvision==0.21.0+cu124' 'torchaudio==2.6.0+cu124'
  uv pip install --python "$target_or_partial/bin/python" \
    --index-strategy unsafe-best-match \
    --extra-index-url https://download.pytorch.org/whl/cu124 \
    -r "$source/requirements.txt"
  finish_env ovi "$key" "$target_or_partial"
  note "Ovi still requires a compatible FlashAttention build; video-ai doctor reports whether it is present"
}

sync_env() {
  local selector="${1:-core}"
  init_layout
  export UV_CACHE_DIR="$cache_root/uv"
  export HF_HOME="$cache_root/huggingface"
  case "$selector" in
    core) sync_comfy_env ;;
    comfyui) sync_comfy_env ;;
    audio)
      sync_chatterbox_env
      sync_locked_uv_env ace-step
      sync_locked_uv_env whisperx
      ;;
    chatterbox) sync_chatterbox_env ;;
    ace-step|whisperx) sync_locked_uv_env "$selector" ;;
    wangp) sync_wangp_env ;;
    ovi) sync_ovi_env ;;
    enhancement|rife|practical-rife) sync_rife_env ;;
    all)
      sync_comfy_env
      sync_chatterbox_env
      sync_locked_uv_env ace-step
      sync_locked_uv_env whisperx
      sync_wangp_env
      sync_ovi_env
      sync_rife_env
      ;;
    *) die "unknown environment or profile: $selector" ;;
  esac
}

prepare_rife_model() {
  local archive="$models_root/rife/rife-v4.25.zip"
  local target="$models_root/rife/rife-v4.25"
  local partial="$target.partial.$$"
  local model_dir="$partial/train_log"
  local required
  [[ -f "$archive" ]] || die "RIFE archive is missing after model sync: $archive"
  if [[ -f "$target/.video-ai-complete" ]]; then
    note "Practical-RIFE 4.25 model already extracted"
    return
  fi
  [[ ! -e "$target" ]] || die "incomplete RIFE model directory requires inspection: $target"
  [[ ! -e "$partial" ]] || die "temporary RIFE model path already exists: $partial"
  mkdir -p "$model_dir"
  unzip -q -j "$archive" \
    train_log/flownet.pkl \
    train_log/IFNet_HDv3.py \
    train_log/refine.py \
    train_log/RIFE_HDv3.py \
    -d "$model_dir"
  for required in flownet.pkl IFNet_HDv3.py refine.py RIFE_HDv3.py; do
    [[ -s "$model_dir/$required" ]] || die "RIFE archive is missing allowlisted file: $required"
  done
  touch "$partial/.video-ai-complete"
  mv "$partial" "$target"
  note "Practical-RIFE 4.25 model extracted: $target"
}

sync_models() {
  local profile="${1:-core}"
  local matched=0
  local restricted
  local restricted_display
  local item_profile name url destination size sha256 license
  local target partial actual bad available reserve_bytes required_bytes partial_size
  init_layout

  restricted="$(jq -r --arg profile "$profile" '
    .[]
    | select(($profile == "all" or .profile == $profile) and (.license | contains("CC-BY-NC")))
    | .name
  ' "$models_manifest")"
  if [[ -n "$restricted" && "${VIDEO_AI_ALLOW_RESTRICTED:-0}" != 1 ]]; then
    restricted_display="${restricted//$'\n'/, }"
    die "selected profile contains non-commercial models ($restricted_display); review their terms, then explicitly set VIDEO_AI_ALLOW_RESTRICTED=1 if appropriate"
  fi

  while IFS=$'\t' read -r item_profile name url destination size sha256 license; do
    [[ "$profile" == "all" || "$profile" == "$item_profile" ]] || continue
    matched=1

    target="$models_root/$destination"
    partial="$target.partial"
    mkdir -p "$(dirname "$target")"

    if [[ -f "$target" ]]; then
      actual="$(sha256sum "$target" | awk '{print $1}')"
      [[ "$actual" == "$sha256" ]] ||
        die "checksum mismatch for existing model: $target"
      note "$name already verified"
      continue
    fi

    available="$(df --output=avail -B1 "$games_root" | tail -n 1 | tr -d '[:space:]')"
    reserve_bytes=$((reserve_gib * 1024 * 1024 * 1024))
    required_bytes="$size"
    if [[ -f "$partial" ]]; then
      partial_size="$(stat -c %s "$partial")"
      if (( partial_size < required_bytes )); then
        required_bytes=$((required_bytes - partial_size))
      else
        required_bytes=0
      fi
    fi
    (( available - required_bytes >= reserve_bytes )) ||
      die "downloading $name would violate the ${reserve_gib} GiB Games-volume reserve"

    note "downloading $name to $target"
    curl --fail --location --retry 5 --retry-delay 2 --continue-at - \
      --output "$partial" "$url"
    actual="$(sha256sum "$partial" | awk '{print $1}')"
    if [[ "$actual" != "$sha256" ]]; then
      bad="$partial.bad.$(date +%Y%m%d%H%M%S)"
      mv "$partial" "$bad"
      die "checksum mismatch for $name; retained invalid download at $bad"
    fi
    mv "$partial" "$target"
    printf '%s\t%s\t%s\n' "$name" "$sha256" "$license"
  done < <(jq -r '.[] | [.profile, .name, .url, .destination, (.size | tostring), .sha256, .license] | @tsv' "$models_manifest")

  [[ "$matched" == 1 ]] || die "unknown or empty model profile: $profile"
  if [[ "$profile" == enhancement || "$profile" == all ]]; then
    prepare_rife_model
  fi
}

sync_workflows() {
  local profile="${1:-core}"
  local destination="$state_root/comfyui/user/default/workflows/video-ai"
  local matched=0
  local item_profile name url target partial
  init_layout
  mkdir -p "$destination"
  while IFS=$'\t' read -r item_profile name url; do
    [[ "$profile" == "all" || "$profile" == "$item_profile" ]] || continue
    matched=1
    target="$destination/$name"
    partial="$target.partial.$$"
    note "syncing workflow $name"
    curl --fail --location --retry 3 --output "$partial" "$url"
    jq -e . "$partial" >/dev/null
    mv "$partial" "$target"
  done < <(jq -r '.[] | [.profile, .name, .url] | @tsv' "$workflows_manifest")
  [[ "$matched" == 1 ]] || die "unknown or empty workflow profile: $profile"
}

new_project() {
  local slug="${1:-}"
  [[ "$slug" =~ ^[a-z0-9][a-z0-9._-]*$ ]] ||
    die "project slug must contain only lowercase letters, numbers, dots, underscores, and hyphens"
  init_layout
  local project="$projects_root/$slug"
  [[ ! -e "$project" ]] || die "project already exists: $project"
  mkdir -p "$project/assets" "$project/audio" "$project/captions" "$project/resolve" "$project/shots"
  jq -n \
    --arg slug "$slug" \
    --arg created "$(date --iso-8601=seconds)" \
    '{schema: 1, slug: $slug, createdAt: $created, generations: []}' >"$project/project.json"
  chmod 700 "$project"
  printf '%s\n' "$project"
}

make_proxy() {
  local input="${1:-}"
  local output="${2:-}"
  [[ -f "$input" ]] || die "input video not found: $input"
  if [[ -z "$output" ]]; then
    output="${input%.*}.dnxhr.mov"
  fi
  ffmpeg -hide_banner -y -i "$input" \
    -map 0:v:0 -map '0:a?' \
    -c:v dnxhd -profile:v dnxhr_hq -pix_fmt yuv422p \
    -c:a pcm_s24le -ar 48000 "$output"
  printf '%s\n' "$output"
}

doctor() {
  local failures=0
  local mount_target
  printf '%-24s %s\n' 'Games root' "$games_root"
  if mount_target="$(findmnt -n -o TARGET -T "$games_root" 2>/dev/null)" && [[ "$mount_target" == "$games_root" ]]; then
    printf '%-24s %s\n' 'Games mount' 'ok'
  else
    printf '%-24s %s\n' 'Games mount' "FAILED (${mount_target:-not found})"
    failures=$((failures + 1))
  fi
  printf '%-24s %s\n' 'Games free' "$(df -h --output=avail "$games_root" | tail -n 1 | tr -d '[:space:]')"
  printf '%-24s %s\n' 'Root free' "$(df -h --output=avail / | tail -n 1 | tr -d '[:space:]')"
  printf '%-24s %s\n' 'Data free' "$(df -h --output=avail /data | tail -n 1 | tr -d '[:space:]')"

  if nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader; then
    :
  else
    printf '%-24s %s\n' 'NVIDIA' 'FAILED'
    failures=$((failures + 1))
  fi

  for app in comfyui chatterbox ace-step whisperx wangp ovi practical-rife; do
    if [[ -L "$envs_root/$app/current" && -x "$envs_root/$app/current/bin/python" ]]; then
      printf '%-24s %s\n' "$app environment" 'ready'
    else
      printf '%-24s %s\n' "$app environment" 'not synced'
    fi
  done

  if [[ -x "$envs_root/comfyui/current/bin/python" ]]; then
    if "$envs_root/comfyui/current/bin/python" -c \
      'import torch; assert torch.cuda.is_available(); print(torch.__version__, torch.cuda.get_device_name(0))'; then
      printf '%-24s %s\n' 'ComfyUI CUDA/imports' 'ok'
    else
      printf '%-24s %s\n' 'ComfyUI CUDA/imports' 'FAILED'
      failures=$((failures + 1))
    fi
  fi
  if [[ -x "$envs_root/chatterbox/current/bin/python" ]]; then
    if "$envs_root/chatterbox/current/bin/python" -c \
      'import torch, torchaudio; from chatterbox.tts_turbo import ChatterboxTurboTTS; assert torch.cuda.is_available()'; then
      printf '%-24s %s\n' 'Chatterbox CUDA/imports' 'ok'
    else
      printf '%-24s %s\n' 'Chatterbox CUDA/imports' 'FAILED'
      failures=$((failures + 1))
    fi
  fi
  if [[ -x "$envs_root/ace-step/current/bin/python" ]]; then
    if "$envs_root/ace-step/current/bin/python" -c \
      'import torch, flash_attn, acestep; assert torch.cuda.is_available()'; then
      printf '%-24s %s\n' 'ACE-Step CUDA/imports' 'ok'
    else
      printf '%-24s %s\n' 'ACE-Step CUDA/imports' 'FAILED'
      failures=$((failures + 1))
    fi
  fi
  if [[ -x "$envs_root/whisperx/current/bin/python" ]]; then
    if "$envs_root/whisperx/current/bin/python" -c \
      'import torch, whisperx; assert torch.cuda.is_available()'; then
      printf '%-24s %s\n' 'WhisperX CUDA/imports' 'ok'
    else
      printf '%-24s %s\n' 'WhisperX CUDA/imports' 'FAILED'
      failures=$((failures + 1))
    fi
  fi
  if [[ -x "$envs_root/wangp/current/bin/python" ]]; then
    if "$envs_root/wangp/current/bin/python" -c \
      'import torch, gradio, onnxruntime; assert torch.cuda.is_available(); assert "CUDAExecutionProvider" in onnxruntime.get_available_providers()'; then
      printf '%-24s %s\n' 'WanGP CUDA/imports' 'ok'
    else
      printf '%-24s %s\n' 'WanGP CUDA/imports' 'FAILED'
      failures=$((failures + 1))
    fi
  fi
  if [[ -x "$envs_root/practical-rife/current/bin/python" ]]; then
    if "$envs_root/practical-rife/current/bin/python" -c \
      'import torch, cv2, skvideo.io; assert torch.cuda.is_available()'; then
      printf '%-24s %s\n' 'RIFE CUDA/imports' 'ok'
    else
      printf '%-24s %s\n' 'RIFE CUDA/imports' 'FAILED'
      failures=$((failures + 1))
    fi
  fi
  if [[ -x "$envs_root/ovi/current/bin/python" ]]; then
    if "$envs_root/ovi/current/bin/python" -c 'import flash_attn' 2>/dev/null; then
      printf '%-24s %s\n' 'Ovi FlashAttention' 'ready'
    else
      printf '%-24s %s\n' 'Ovi FlashAttention' 'missing (standalone Ovi cannot run yet)'
    fi
  fi

  return "$failures"
}

status_report() {
  require_safe_paths
  jq -r '.[] | [.name, .profile, .revision] | @tsv' "$apps_manifest"
  printf '\nDisk usage:\n'
  du -sh "$models_root" "$video_ai_root" 2>/dev/null || true
  printf '\nServices:\n'
  systemctl --user --no-pager --plain --type=service --state=running \
    'comfyui.service' 'wangp.service' 'ace-step.service' 2>/dev/null || true
}

usage() {
  cat <<'EOF'
Usage: video-ai <command> [arguments]

Commands:
  init                         Create the guarded Games-volume layout
  doctor                       Check mounts, capacity, NVIDIA, and environments
  status                       Show pinned revisions, disk use, and services
  apps sync [name|profile]     Sync pinned application sources (default: core)
  env sync [name|profile]      Build isolated Python environments (default: core)
  models sync [profile]        Download checksum-pinned models (default: core)
  workflows sync [profile]     Install pinned ComfyUI workflows (default: core)
  new <slug>                   Create a provenance-ready project directory
  proxy <input> [output]       Make a Resolve-friendly DNxHR/PCM intermediate

Profiles: core, audio, experiments, ovi, enhancement, all

Restricted model artifacts are refused unless VIDEO_AI_ALLOW_RESTRICTED=1 is
set after reviewing their license and intended use.
EOF
}

command="${1:-}"
shift || true
case "$command" in
  init) init_layout ;;
  doctor) doctor ;;
  status) status_report ;;
  apps)
    [[ "${1:-}" == sync ]] || die "expected: video-ai apps sync [selector]"
    shift
    sync_apps "${1:-core}"
    ;;
  env)
    [[ "${1:-}" == sync ]] || die "expected: video-ai env sync [selector]"
    shift
    sync_env "${1:-core}"
    ;;
  models)
    [[ "${1:-}" == sync ]] || die "expected: video-ai models sync [profile]"
    shift
    sync_models "${1:-core}"
    ;;
  workflows)
    [[ "${1:-}" == sync ]] || die "expected: video-ai workflows sync [profile]"
    shift
    sync_workflows "${1:-core}"
    ;;
  new) new_project "${1:-}" ;;
  proxy) make_proxy "${1:-}" "${2:-}" ;;
  help|-h|--help|'') usage ;;
  *) die "unknown command: $command (run video-ai help)" ;;
esac
