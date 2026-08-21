#!/usr/bin/env bash

set -uo pipefail

repo_dir="${1:-}"

if [[ -z "${repo_dir}" || ! -f "${repo_dir}/flake.nix" ]]; then
  echo "AI desktop updater: invalid NixOS config directory: ${repo_dir}" >&2
  exit 1
fi

if [[ "$(uname -m)" != "x86_64" ]]; then
  echo "AI desktop updater: only x86_64 is configured in this flake" >&2
  exit 1
fi

latest_package() {
  local index_file="$1"
  awk '
    BEGIN { RS = ""; FS = "\n" }
    {
      version = filename = sha256 = ""
      for (i = 1; i <= NF; i++) {
        if ($i ~ /^Version: /) version = substr($i, 10)
        if ($i ~ /^Filename: /) filename = substr($i, 11)
        if ($i ~ /^SHA256: /) sha256 = substr($i, 9)
      }
      if (version != "" && filename != "" && sha256 != "") {
        printf "%s\t%s\t%s\n", version, filename, sha256
      }
    }
  ' "${index_file}" | sort -t $'\t' -k1,1V | tail -n 1
}

write_source_pin() {
  local source_file="$1"
  local version="$2"
  local url="$3"
  local hash="$4"
  local new_source

  new_source="$(mktemp "${source_file}.tmp.XXXXXX")" || return 1
  if ! printf '{\n  version = "%s";\n  src = {\n    url = "%s";\n    hash = "%s";\n  };\n}\n' \
    "${version}" "${url}" "${hash}" > "${new_source}"; then
    return 1
  fi
  mv -- "${new_source}" "${source_file}"
}

update_apt_package() {
  local display_name="$1"
  local package_name="$2"
  local index_url="$3"
  local repository_url="$4"
  local source_file="$5"
  local index_file latest version filename sha256 url expected_hash
  local current_version current_hash prefetch_json downloaded_hash store_path

  index_file="$(mktemp "${TMPDIR:-/tmp}/ai-desktop-index.XXXXXX")" || return 1
  if ! curl --retry 2 --connect-timeout 10 --max-time 30 -fsSL \
    "${index_url}" -o "${index_file}"; then
    rm -f -- "${index_file}"
    return 1
  fi

  latest="$(latest_package "${index_file}")"
  rm -f -- "${index_file}"
  if [[ -z "${latest}" ]]; then
    echo "${display_name}: package index contained no releases" >&2
    return 1
  fi

  IFS=$'\t' read -r version filename sha256 <<< "${latest}"
  if [[ ! "${version}" =~ ^[0-9A-Za-z.+:~_-]+$ ]] ||
    [[ ! "${filename}" =~ ^pool/[0-9A-Za-z._/+~-]+$ ]] ||
    [[ "${filename}" == *".."* ]] ||
    [[ ! "${sha256}" =~ ^[0-9a-fA-F]{64}$ ]]; then
    echo "${display_name}: refused malformed package metadata" >&2
    return 1
  fi

  url="${repository_url}/${filename}"
  expected_hash="$(nix hash convert --hash-algo sha256 --to sri "${sha256}")" || return 1
  current_version="$(sed -n 's/^[[:space:]]*version = "\([^"]*\)";/\1/p' "${source_file}" | head -n 1)"
  current_hash="$(sed -n 's/^[[:space:]]*hash = "\([^"]*\)";/\1/p' "${source_file}" | head -n 1)"

  if [[ "${version}" == "${current_version}" && "${expected_hash}" == "${current_hash}" ]]; then
    echo "${display_name} ${version} is up to date"
    return 0
  fi

  echo "Updating ${display_name}: ${current_version:-unavailable} -> ${version}"
  if ! prefetch_json="$(nix store prefetch-file --json --expected-hash "${expected_hash}" "${url}")"; then
    return 1
  fi
  downloaded_hash="$(jq -r '.hash // empty' <<< "${prefetch_json}")"
  store_path="$(jq -r '.storePath // empty' <<< "${prefetch_json}")"
  if [[ "${downloaded_hash}" != "${expected_hash}" || ! -f "${store_path}" ]]; then
    echo "${display_name}: downloaded package did not match the repository checksum" >&2
    return 1
  fi
  if [[ "$(dpkg-deb -f "${store_path}" Package)" != "${package_name}" ]] ||
    [[ "$(dpkg-deb -f "${store_path}" Version)" != "${version}" ]] ||
    [[ "$(dpkg-deb -f "${store_path}" Architecture)" != "amd64" ]]; then
    echo "${display_name}: downloaded package metadata did not match the index" >&2
    return 1
  fi

  write_source_pin "${source_file}" "${version}" "${url}" "${expected_hash}"
}

status=0

if ! update_apt_package \
  "ChatGPT" \
  "chatgpt" \
  "https://persistent.oaistatic.com/codex-app-prod/linux/deb/dists/stable/main/binary-amd64/Packages" \
  "https://persistent.oaistatic.com/codex-app-prod/linux/deb" \
  "${repo_dir}/pkgs/chatgpt-linux/source.nix"; then
  echo "Warning: could not check ChatGPT updates; keeping the pinned release." >&2
  status=1
fi

if ! update_apt_package \
  "Claude Desktop" \
  "claude-desktop" \
  "https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages" \
  "https://downloads.claude.ai/claude-desktop/apt/stable" \
  "${repo_dir}/pkgs/claude-desktop/source.nix"; then
  echo "Warning: could not check Claude Desktop updates; keeping the pinned release." >&2
  status=1
fi

exit "${status}"
