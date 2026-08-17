#!/usr/bin/env bash
set -euo pipefail

model="${LLAMA_WEIRDCOMPOUND_24B_MODEL:-}"
if (($# > 0)); then
  model="$1"
  shift
fi
if [[ -n "$model" ]]; then
  exec llm-serve weird --model "$model" -- "$@"
fi
exec llm-serve weird -- "$@"
