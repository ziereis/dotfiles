#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
source "$ROOT/packages/github.sh"
LOCK_FILE="$ROOT/packages/github.lock"

command -v curl >/dev/null
command -v jq >/dev/null

github_release_json() {
  local repo=$1 tag=$2
  local curl_args=(-fsSL --retry 3)
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    curl_args+=(-H "Authorization: Bearer $GITHUB_TOKEN")
    curl_args+=(-H "X-GitHub-Api-Version: 2022-11-28")
  fi
  curl "${curl_args[@]}" "https://api.github.com/repos/$repo/releases/tags/$tag"
}

for tool in "${GITHUB_TOOLS[@]}"; do
  repo=$(github_repo "$tool")
  tag=$(awk -F '\t' -v tool="$tool" '$1 == tool { print $4; exit }' "$LOCK_FILE")
  json=$(github_release_json "$repo" "$tag")
  for platform in linux-x86_64 linux-arm64 macos-arm64; do
    line=$(awk -F '\t' -v tool="$tool" -v platform="$platform" \
      '$1 == tool && $2 == platform { print }' "$LOCK_FILE")
    [[ -n "$line" ]] || { echo "$tool/$platform is not locked" >&2; exit 1; }
    IFS=$'\t' read -r _ _ locked_repo locked_tag asset expected binary <<<"$line"
    [[ "$locked_repo" == "$repo" && "$locked_tag" == "$tag" && -n "$binary" ]] || exit 1
    actual=$(jq -r --arg asset "$asset" '.assets[] | select(.name == $asset) | .digest // empty' <<<"$json")
    [[ "$actual" == "sha256:$expected" ]] || {
      echo "$tool/$platform: locked digest no longer matches GitHub" >&2
      exit 1
    }
  done
done

echo "locked release asset tests passed"
