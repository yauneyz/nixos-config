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
extra_index_url="${ML_UV_EXTRA_INDEX_URL:-}"
prerelease_mode="${ML_UV_PRERELEASE:-}"
index_strategy="${ML_UV_INDEX_STRATEGY:-}"

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
    # vLLM's default and nightly wheel variants currently center on CUDA 12.9.
    # Prefer the matching PyTorch index instead of letting uv jump to cu130 on
    # newer drivers, which can leave vLLM extensions looking for the wrong CUDA
    # runtime family.
    if [[ -f "$requirements_file" ]] && grep -Eq '^vllm($|==0\.16\.0$)' "$requirements_file"; then
      printf '%s\n' "cu129"
    else
      printf '%s\n' "auto"
    fi
    return 0
  fi

  printf '\n'
}

runtime_library_path() {
  local path_parts=()
  local dir
  local nullglob_was_set=0

  # nix-ld helps unpatched executables, but Python virtualenv packages loaded
  # via dlopen() still need LD_LIBRARY_PATH set explicitly.
  if [[ -n "${NIX_LD_LIBRARY_PATH:-}" ]]; then
    path_parts+=("$NIX_LD_LIBRARY_PATH")
  fi

  # CUDA wheels still need the host driver libraries from the live driver path.
  if [[ -d /run/opengl-driver/lib ]]; then
    path_parts+=("/run/opengl-driver/lib")
  fi

  if [[ -d /run/opengl-driver-32/lib ]]; then
    path_parts+=("/run/opengl-driver-32/lib")
  fi

  # Expose wheel-bundled libtorch/CUDA shared objects for extensions like
  # vllm/_C. These wheels bundle their own runtimes under site-packages.
  if shopt -q nullglob; then
    nullglob_was_set=1
  fi
  shopt -s nullglob
  for dir in \
    "$env_dir"/lib/python*/site-packages/torch/lib \
    "$env_dir"/lib/python*/site-packages/nvidia/*/lib
  do
    if [[ -d "$dir" ]]; then
      path_parts+=("$dir")
    fi
  done
  if ((nullglob_was_set == 0)); then
    shopt -u nullglob
  fi

  if [[ -n "${LD_LIBRARY_PATH:-}" ]]; then
    path_parts+=("$LD_LIBRARY_PATH")
  fi

  if [[ "${#path_parts[@]}" -eq 0 ]]; then
    return 0
  fi

  local IFS=:
  printf '%s\n' "${path_parts[*]}"
}

export_runtime_library_path() {
  local value=""
  local python_include_dir=""

  value="$(runtime_library_path)"
  if [[ -n "$value" ]]; then
    export LD_LIBRARY_PATH="$value"
  fi

  if [[ -z "${TRITON_LIBCUDA_PATH:-}" ]]; then
    if [[ -e /run/opengl-driver/lib/libcuda.so.1 ]]; then
      export TRITON_LIBCUDA_PATH="/run/opengl-driver/lib"
    elif [[ -e /run/opengl-driver-32/lib/libcuda.so.1 ]]; then
      export TRITON_LIBCUDA_PATH="/run/opengl-driver-32/lib"
    fi
  fi

  if [[ -x "$env_dir/bin/python" ]]; then
    python_include_dir="$("$env_dir/bin/python" -c 'import sysconfig; print(sysconfig.get_config_var("INCLUDEPY") or "")')"
    if [[ -n "$python_include_dir" && -e "$python_include_dir/Python.h" ]]; then
      case ":${CPATH:-}:" in
        *":$python_include_dir:"*) ;;
        *)
          if [[ -n "${CPATH:-}" ]]; then
            export CPATH="$python_include_dir:$CPATH"
          else
            export CPATH="$python_include_dir"
          fi
          ;;
      esac
    fi
  fi
}

manifest_value() {
  local requirements_hash python_cmd python_version torch_backend

  requirements_hash="$(sha256sum "$requirements_file" | awk '{print $1}')"
  python_cmd="$(find_python)"
  python_version="$("$python_cmd" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
  torch_backend="$(detect_torch_backend)"

  printf 'v4|requirements=%s|python=%s|torch-backend=%s|extra-index=%s|prerelease=%s|index-strategy=%s\n' \
    "$requirements_hash" \
    "$python_version" \
    "${torch_backend:-default}" \
    "${extra_index_url:-default}" \
    "${prerelease_mode:-default}" \
    "${index_strategy:-default}"
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

  # Backend changes like cu130 -> cu129 are not reliably repaired by an
  # in-place install because uv may consider the existing local-version wheels
  # satisfactory. Recreate the managed env whenever a sync is required.
  uv venv "$env_dir" --python "$python_cmd" --seed --clear

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

  if [[ -n "$prerelease_mode" ]]; then
    install_cmd+=(
      --prerelease
      "$prerelease_mode"
    )
  fi

  if [[ -n "$extra_index_url" ]]; then
    install_cmd+=(
      --extra-index-url
      "$extra_index_url"
    )
  fi

  if [[ -n "$index_strategy" ]]; then
    install_cmd+=(
      --index-strategy
      "$index_strategy"
    )
  fi

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
    export_runtime_library_path
    exec "$env_dir/bin/python" "$@"
    ;;
  run)
    shift
    if [[ "$#" -eq 0 ]]; then
      usage >&2
      exit 1
    fi

    ensure_env
    export_runtime_library_path

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
