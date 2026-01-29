#!/usr/bin/env bash
set -euo pipefail

project_dir="${THINKY_ELECTRON_DIR:-$HOME/development/clojure/owl/electron}"

if [ ! -d "$project_dir" ]; then
  echo "Thinky electron dir not found: $project_dir" >&2
  exit 1
fi

cd "$project_dir"

if command -v steam-run >/dev/null 2>&1; then
  exec steam-run npm run dist -- --linux "$@"
fi

npm run dist -- --linux "$@"
