#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<EOF
Usage: rebuild [host] [switch|boot|test|build|dry-build|dry-activate]
       rebuild [switch|boot|test|build|dry-build|dry-activate]
EOF
}

is_mode() {
  case "${1:-}" in
    switch|boot|test|build|dry-build|dry-activate)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

host=""
mode="switch"

case "$#" in
  0)
    ;;
  1)
    if [[ "${1}" == "-h" || "${1}" == "--help" ]]; then
      usage
      exit 0
    elif is_mode "${1}"; then
      mode="${1}"
    else
      host="${1}"
    fi
    ;;
  2)
    host="${1}"
    mode="${2}"
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

if [[ -z "${host}" ]]; then
  host="$(hostname -s 2>/dev/null || hostname)"
  host="${host%%.*}"
fi

if [[ -z "${host}" || "${host}" == *[!A-Za-z0-9_-]* ]]; then
  echo "Invalid host: ${host}" >&2
  exit 1
fi

if ! is_mode "${mode}"; then
  echo "Invalid mode: ${mode}" >&2
  usage >&2
  exit 1
fi

repo_dir="${NIXOS_CONFIG_DIR:-}"

if [[ -z "${repo_dir}" || ! -f "${repo_dir}/flake.nix" ]]; then
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
  source_repo_dir="$(cd -- "${script_dir}/.." 2>/dev/null && pwd || true)"

  if [[ -f "${source_repo_dir}/flake.nix" ]]; then
    repo_dir="${source_repo_dir}"
  else
    repo_dir="${HOME}/nixos-config"
  fi
fi

if [[ ! -f "${repo_dir}/flake.nix" ]]; then
  echo "Could not find flake.nix in ${repo_dir}" >&2
  echo "Set NIXOS_CONFIG_DIR to your nixos-config checkout." >&2
  exit 1
fi

echo "Checking ChatGPT and Claude Desktop updates"
if ! bash "${repo_dir}/scripts/update-ai-desktop-apps.sh" "${repo_dir}"; then
  echo "Warning: one or more desktop app update checks failed; rebuilding with the current pins." >&2
fi

echo "Rebuilding NixOS host '${host}' with '${mode}' from ${repo_dir}"

cmd=(nixos-rebuild "${mode}" --flake "${repo_dir}#${host}")

case "${mode}" in
  build|dry-build)
    exec "${cmd[@]}"
    ;;
  *)
    if [[ "${EUID}" -eq 0 ]]; then
      exec "${cmd[@]}"
    else
      exec sudo "${cmd[@]}"
    fi
    ;;
esac
