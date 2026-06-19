#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$ROOT/packages/github.sh"

LOCK_FILE="$ROOT/packages/github.lock"
TMP_LOCK=$(mktemp "${TMPDIR:-/tmp}/github-packages.XXXXXX")
trap 'rm -f "$TMP_LOCK"' EXIT

github_release_json() {
  local repo=$1
  local curl_args=(-fsSL --retry 3)
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    curl_args+=(-H "Authorization: Bearer $GITHUB_TOKEN")
    curl_args+=(-H "X-GitHub-Api-Version: 2022-11-28")
  fi
  curl "${curl_args[@]}" "https://api.github.com/repos/$repo/releases/latest"
}

printf '# tool\tplatform\trepository\ttag\tasset\tsha256\tbinary\n' >"$TMP_LOCK"

for tool in "${GITHUB_TOOLS[@]}"; do
  repo=$(github_repo "$tool")
  binary=$(github_binary "$tool")
  json=$(github_release_json "$repo")
  tag=$(jq -r '.tag_name' <<<"$json")
  for platform in linux-x86_64 linux-arm64 macos-arm64; do
    pattern=$(github_asset_pattern "$tool" "$platform")
    count=$(jq --arg pattern "$pattern" '[.assets[] | select(.name | test($pattern))] | length' <<<"$json")
    [[ "$count" == 1 ]] || {
      echo "$tool/$platform: expected one asset, found $count" >&2
      exit 1
    }
    asset=$(jq -r --arg pattern "$pattern" '.assets[] | select(.name | test($pattern)) | .name' <<<"$json")
    digest=$(jq -r --arg pattern "$pattern" '.assets[] | select(.name | test($pattern)) | .digest // empty' <<<"$json")
    [[ "$digest" == sha256:* ]] || {
      echo "$tool/$platform: asset has no SHA-256 digest" >&2
      exit 1
    }
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$tool" "$platform" "$repo" "$tag" "$asset" "${digest#sha256:}" "$binary" >>"$TMP_LOCK"
  done
done

mv "$TMP_LOCK" "$LOCK_FILE"
trap - EXIT
echo "updated $LOCK_FILE"
