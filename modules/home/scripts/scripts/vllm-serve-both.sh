#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: vllm-serve-both [chat-model] [embeddings-model]

Starts the chat vLLM server and the CPU embeddings server together in one terminal.

Environment overrides:
  VLLM_CHAT_MODEL
  VLLM_EMBEDDINGS_MODEL
  VLLM_CHAT_PORT
  VLLM_EMBEDDINGS_PORT
  VLLM_CHAT_SERVE_ARGS
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "${1:-}" == "help" ]]; then
  usage
  exit 0
fi

repo_root="${NIXOS_CONFIG_DIR:-$HOME/nixos-config}"
chat_model="${1:-${VLLM_CHAT_MODEL:-}}"
embeddings_model="${2:-${VLLM_EMBEDDINGS_MODEL:-}}"
chat_pid=""
embeddings_pid=""
chat_cmd=(bash "$repo_root/modules/home/scripts/scripts/vllm-serve.sh")
embeddings_cmd=(bash "$repo_root/modules/home/scripts/scripts/vllm-serve-embeddings.sh")

if [[ -n "$chat_model" ]]; then
  chat_cmd+=("$chat_model")
fi

if [[ -n "$embeddings_model" ]]; then
  embeddings_cmd+=("$embeddings_model")
fi

cleanup() {
  local exit_code="$?"

  if [[ -n "$chat_pid" ]] && kill -0 "$chat_pid" 2>/dev/null; then
    kill "$chat_pid" 2>/dev/null || true
  fi

  if [[ -n "$embeddings_pid" ]] && kill -0 "$embeddings_pid" 2>/dev/null; then
    kill "$embeddings_pid" 2>/dev/null || true
  fi

  wait "$chat_pid" "$embeddings_pid" 2>/dev/null || true
  exit "$exit_code"
}

trap cleanup EXIT INT TERM

(
  export VLLM_PORT="${VLLM_CHAT_PORT:-11434}"
  export VLLM_SERVE_ARGS="${VLLM_CHAT_SERVE_ARGS:-${VLLM_SERVE_ARGS:-}}"
  unset VLLM_RUNNER
  unset VLLM_CONVERT

  exec "${chat_cmd[@]}"
) &
chat_pid="$!"

(
  export VLLM_PORT="${VLLM_EMBEDDINGS_PORT:-11435}"

  exec "${embeddings_cmd[@]}"
) &
embeddings_pid="$!"

wait -n "$chat_pid" "$embeddings_pid"
