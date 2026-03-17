#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
local_copy_path="$script_dir/thinky.AppImage"
electron_dist_path="$HOME/development/clojure/owl/electron/dist/thinky.AppImage"
default_nix_path="$script_dir/default.nix"

appimage_path="${1:-$local_copy_path}"

# Backward compatibility: if no local copy exists, fall back to the electron dist output.
if [[ ! -f "$appimage_path" && -f "$electron_dist_path" ]]; then
  appimage_path="$electron_dist_path"
fi

if [[ ! -f "$appimage_path" ]]; then
  echo "Thinky AppImage not found." >&2
  echo "Checked: $appimage_path" >&2
  if [[ "$appimage_path" != "$electron_dist_path" ]]; then
    echo "Fallback checked: $electron_dist_path" >&2
  fi
  echo "Usage: thinky-hash /path/to/thinky.AppImage" >&2
  exit 1
fi

# Add to the Nix store (fixed-output) so requireFile can find it.
store_path=$(nix-store --add-fixed sha256 "$appimage_path")

# Compute the Nix base32 hash expected by requireFile.
sha256=$(nix-hash --type sha256 --flat --base32 "$appimage_path")
export THINKY_SHA256="$sha256"
export THINKY_DEFAULT_NIX="$default_nix_path"

python3 - <<'PY'
import os
import pathlib

file_path = pathlib.Path(os.environ["THINKY_DEFAULT_NIX"])
text = file_path.read_text()
old = "sha256 = \""
start = text.find(old)
if start == -1:
    raise SystemExit("sha256 attribute not found in default.nix")
start += len(old)
end = text.find('"', start)
if end == -1:
    raise SystemExit("unterminated sha256 string in default.nix")

new_hash = os.environ["THINKY_SHA256"]
text = text[:start] + new_hash + text[end:]
file_path.write_text(text)
PY

# shellcheck disable=SC2016
printf 'Updated hash to %s in %s and added to store at %s\n' "$sha256" "$default_nix_path" "$store_path"
