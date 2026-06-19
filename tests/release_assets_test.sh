#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
INSTALLER="$ROOT/install_packages.sh"

command -v curl >/dev/null
command -v jq >/dev/null

github_release_json() {
  local repo=$1
  local curl_args=(-fsSL --retry 3)
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    curl_args+=(-H "Authorization: Bearer $GITHUB_TOKEN")
    curl_args+=(-H "X-GitHub-Api-Version: 2022-11-28")
  fi
  curl "${curl_args[@]}" "https://api.github.com/repos/$repo/releases/latest"
}

for target in "Linux x86_64" "Linux aarch64" "Darwin arm64"; do
  read -r os arch <<<"$target"
  while IFS= read -r line; do
    [[ "$line" == release\[* ]] || continue
    tool=${line#release[}
    tool=${tool%%]*}
    rest=${line#*: }
    repo=${rest%% / *}
    pattern=${rest#* / }
    json=$(github_release_json "$repo")
    count=$(jq --arg pattern "$pattern" '[.assets[] | select(.name | test($pattern))] | length' <<<"$json")
    [[ "$count" == 1 ]] || {
      echo "$os/$arch $tool: expected one asset, found $count" >&2
      exit 1
    }
    digest=$(jq -r --arg pattern "$pattern" '.assets[] | select(.name | test($pattern)) | .digest // empty' <<<"$json")
    [[ "$digest" == sha256:* ]] || {
      echo "$os/$arch $tool: selected asset has no SHA-256 digest" >&2
      exit 1
    }
  done < <(DOTFILES_OS="$os" DOTFILES_ARCH="$arch" "$INSTALLER" --dry-run)
done

echo "release asset tests passed"
