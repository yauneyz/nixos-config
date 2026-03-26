#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ml-env [ensure|sync|path|python|run] [args...]

Commands:
  ensure          Create/update the managed ML environment if needed
  sync            Force a reinstall of pinned ML packages
  path            Print the managed environment path
  python [args]   Run the managed environment's Python
  run <cmd> ...   Run a command installed in the managed environment
EOF
}

repo_root="${NIXOS_CONFIG_DIR:-$HOME/nixos-config}"
requirements_file="${ML_UV_REQUIREMENTS_FILE:-$repo_root/modules/home/scripts/requirements/ml-python.txt}"
env_dir="${ML_UV_ENV_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/nixos-ml}"
manifest_path="${env_dir}/.manifest"

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Required command not found: $cmd" >&2
    exit 1
  fi
}

find_python() {
  local candidate
  for candidate in python3.12 python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  echo "Could not find python3.12, python3, or python on PATH." >&2
  exit 1
}

detect_torch_backend() {
  if [[ -n "${ML_UV_TORCH_BACKEND:-}" ]]; then
    printf '%s\n' "$ML_UV_TORCH_BACKEND"
    return 0
  fi

  if [[ -n "${UV_TORCH_BACKEND:-}" ]]; then
    printf '%s\n' "$UV_TORCH_BACKEND"
    return 0
  fi

  if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
    printf '%s\n' "auto"
    return 0
  fi

  printf '\n'
}

manifest_value() {
  local requirements_hash python_cmd python_version torch_backend

  requirements_hash="$(sha256sum "$requirements_file" | awk '{print $1}')"
  python_cmd="$(find_python)"
  python_version="$("$python_cmd" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
  torch_backend="$(detect_torch_backend)"

  printf 'v1|requirements=%s|python=%s|torch-backend=%s\n' \
    "$requirements_hash" \
    "$python_version" \
    "${torch_backend:-default}"
}

sync_env() {
  local python_cmd install_cmd torch_backend

  require_command uv

  if [[ ! -f "$requirements_file" ]]; then
    echo "Pinned requirements file not found: $requirements_file" >&2
    exit 1
  fi

  python_cmd="$(find_python)"
  torch_backend="$(detect_torch_backend)"

  mkdir -p "$(dirname "$env_dir")"

  if [[ ! -x "$env_dir/bin/python" ]]; then
    uv venv "$env_dir" --python "$python_cmd" --seed
  fi

  install_cmd=(
    uv
    pip
    install
    --python
    "$env_dir/bin/python"
    --upgrade
    --requirement
    "$requirements_file"
  )

  if [[ -n "$torch_backend" ]]; then
    UV_TORCH_BACKEND="$torch_backend" "${install_cmd[@]}"
  else
    "${install_cmd[@]}"
  fi

  printf '%s' "$(manifest_value)" > "$manifest_path"
}

ensure_env() {
  local expected_manifest=""
  local current_manifest=""

  expected_manifest="$(manifest_value)"

  if [[ -f "$manifest_path" ]]; then
    current_manifest="$(<"$manifest_path")"
  fi

  if [[ ! -x "$env_dir/bin/python" || "$current_manifest" != "$expected_manifest" ]]; then
    sync_env
  fi
}

subcommand="${1:-ensure}"

case "$subcommand" in
  ensure)
    ensure_env
    printf '%s\n' "$env_dir"
    ;;
  sync)
    sync_env
    printf '%s\n' "$env_dir"
    ;;
  path)
    printf '%s\n' "$env_dir"
    ;;
  python)
    shift
    ensure_env
    exec "$env_dir/bin/python" "$@"
    ;;
  run)
    shift
    if [[ "$#" -eq 0 ]]; then
      usage >&2
      exit 1
    fi

    ensure_env

    if [[ "$1" == */* ]]; then
      echo "ml-env run expects a command name, not a path: $1" >&2
      exit 1
    fi

    if [[ ! -x "$env_dir/bin/$1" ]]; then
      echo "Command is not installed in the managed ML environment: $1" >&2
      exit 1
    fi

    exec "$env_dir/bin/$1" "${@:2}"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac
