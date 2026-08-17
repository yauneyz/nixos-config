#!/usr/bin/env bash
set -euo pipefail

# Compatibility entry point. New usage should call `llm-serve` directly.
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "${1:-}" == "help" ]]; then
  exec llm-serve --help
fi

if (($# > 0)); then
  model="$1"
  shift
  exec llm-serve omni --model "$model" -- "$@"
fi

exec llm-serve
