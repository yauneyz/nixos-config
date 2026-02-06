#!/usr/bin/env bash
set -euo pipefail

appimage_path="${1:-$HOME/development/clojure/owl/electron/dist/thinky.AppImage}"

if [[ ! -f "$appimage_path" ]]; then
  echo "Thinky AppImage not found at: $appimage_path" >&2
  exit 1
fi

# Add to the Nix store (fixed-output) so requireFile can find it.
store_path=$(nix-store --add-fixed sha256 "$appimage_path")

# Compute the Nix base32 hash expected by requireFile.
sha256=$(nix-hash --type sha256 --flat --base32 "$appimage_path")
export THINKY_SHA256="$sha256"

python3 - <<'PY'
import pathlib

file_path = pathlib.Path("/home/zac/nixos-config/pkgs/thinky/default.nix")
text = file_path.read_text()
old = "sha256 = \""
start = text.find(old)
if start == -1:
    raise SystemExit("sha256 attribute not found in default.nix")
start += len(old)
end = text.find("\"", start)
if end == -1:
    raise SystemExit("unterminated sha256 string in default.nix")

import os
new_hash = os.environ["THINKY_SHA256"]
text = text[:start] + new_hash + text[end:]
file_path.write_text(text)
PY

# shellcheck disable=SC2016
printf 'Updated hash to %s and added to store at %s\n' "$sha256" "$store_path"
