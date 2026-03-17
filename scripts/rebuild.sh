#!/usr/bin/env bash

set -euo pipefail

host="${1:-}"

if [[ -z "${host}" ]]; then
  echo "Usage: $0 <host>"
  exit 1
fi

start_dir="$(pwd)"
trap 'cd "${start_dir}"' EXIT

cd "${HOME}/nixos-config"
sudo nixos-rebuild switch --flake ".#${host}"
