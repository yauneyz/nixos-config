#!/usr/bin/env bash
set -euo pipefail

models_dir="${LLAMA_TAVERN_MODELS_DIR:-/home/zac/Games/Models/tavern}"
mkdir -p "$models_dir"

model="${1:-}"
if [[ -n "$model" ]]; then
  if [[ ! -f "$model" ]]; then
    echo "Model file not found: $model" >&2
    exit 1
  fi
else
  model="$(ls -1t "$models_dir"/*.gguf 2>/dev/null | head -n 1 || true)"
  if [[ -z "$model" ]]; then
    cat >&2 <<EOF
No .gguf models found in $models_dir
Drop a model there (e.g. *.gguf) or pass a path as the first argument.
EOF
    exit 1
  fi
fi

model_file="$(basename "$model")"
if [[ "$model_file" =~ ^(.+)-([0-9]{5})-of-([0-9]{5})\.gguf$ ]]; then
  split_prefix="${BASH_REMATCH[1]}"
  split_idx="${BASH_REMATCH[2]}"
  split_count="${BASH_REMATCH[3]}"
  model_dir="$(dirname "$model")"
  first_split="$model_dir/${split_prefix}-00001-of-${split_count}.gguf"

  if [[ "$split_idx" != "00001" ]]; then
    if [[ -f "$first_split" ]]; then
      echo "Selected shard is ${split_idx}; using first shard: $first_split" >&2
      model="$first_split"
    else
      echo "Missing first GGUF split shard: $first_split" >&2
      exit 1
    fi
  fi

  n_splits=$((10#$split_count))
  missing_splits=()
  for ((i = 1; i <= n_splits; i++)); do
    split_path="$(printf "%s/%s-%05d-of-%s.gguf" "$model_dir" "$split_prefix" "$i" "$split_count")"
    if [[ ! -f "$split_path" ]]; then
      missing_splits+=("$split_path")
    fi
  done

  if (( ${#missing_splits[@]} > 0 )); then
    echo "Missing GGUF split shard(s) required by $model:" >&2
    printf "  %s\n" "${missing_splits[@]}" >&2
    exit 1
  fi
fi

port="${LLAMA_PORT:-11434}"
threads="${LLAMA_THREADS:-$(nproc)}"
ctx="64000"
fit="auto"

extra_args=()
if [[ -n "${LLAMA_SERVER_ARGS:-}" ]]; then
  # Split on spaces intentionally for quick overrides.
  # shellcheck disable=SC2206
  extra_args=(${LLAMA_SERVER_ARGS})
fi

cmd=(
  llama-server
  --model "$model"
  --port "$port"
  --ctx-size "$ctx"
  --threads "$threads"
  --fit "$fit"
)

cmd+=("${extra_args[@]}")

exec "${cmd[@]}"
