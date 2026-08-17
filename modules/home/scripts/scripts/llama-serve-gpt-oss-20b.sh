#!/usr/bin/env bash
set -euo pipefail

model="${LLAMA_GPT_OSS_20B_MODEL:-}"
if (($# > 0)); then
  model="$1"
  shift
fi
if [[ -n "$model" ]]; then
  exec llm-serve oss --model "$model" -- "$@"
fi
exec llm-serve oss -- "$@"
