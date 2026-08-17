#!/usr/bin/env bash
set -euo pipefail

model="${LLAMA_OMNICODER_9B_MODEL:-}"
if (($# > 0)); then
  model="$1"
  shift
fi
if [[ -n "$model" ]]; then
  exec llm-serve omni --model "$model" -- "$@"
fi
exec llm-serve omni -- "$@"
