#!/usr/bin/env bash

set -euo pipefail

host="${1:-}"
mode="${2:-}"

if [[ -z "${host}" ]]; then
  echo "Usage: $0 <host> [switch|boot|test]"
  exit 1
fi

if [[ -z "${mode}" ]]; then
  mode="switch"
fi

case "${mode}" in
  switch|boot|test)
    ;;
  *)
    echo "Invalid mode: ${mode}" >&2
    echo "Expected one of: switch, boot, test" >&2
    exit 1
    ;;
esac

start_dir="$(pwd)"
trap 'cd "${start_dir}"' EXIT

cd "${HOME}/nixos-config"
sudo nixos-rebuild "${mode}" --flake ".#${host}"
