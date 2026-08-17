#!/usr/bin/env bash
set -euo pipefail

model="${LLAMA_EURYALE_70B_MODEL:-}"
if (($# > 0)); then
  model="$1"
  shift
fi
if [[ -n "$model" ]]; then
  exec llm-serve euryale --model "$model" -- "$@"
fi
exec llm-serve euryale -- "$@"
