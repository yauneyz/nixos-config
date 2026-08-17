#!/usr/bin/env bash
set -euo pipefail

model="${LLAMA_CYDONIA_24B_MODEL:-}"
if (($# > 0)); then
  model="$1"
  shift
fi
if [[ -n "$model" ]]; then
  exec llm-serve cydonia --model "$model" -- "$@"
fi
exec llm-serve cydonia -- "$@"
