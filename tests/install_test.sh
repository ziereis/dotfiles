#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
INSTALLER="$ROOT/install_packages.sh"
source "$ROOT/packages/github.sh"

assert_plan() {
  local os=$1 arch=$2 expected=$3 output tool
  output=$(DOTFILES_OS="$os" DOTFILES_ARCH="$arch" "$INSTALLER" --dry-run)
  grep -Fq "platform: $expected" <<<"$output"
  for tool in "${GITHUB_TOOLS[@]}"; do
    grep -Fq "release[$tool]:" <<<"$output"
  done
  grep -Fq "native[claude]: https://claude.ai/install.sh (stable)" <<<"$output"
  grep -Fq "private: ziereis/dotfiles-private" <<<"$output"
  grep -Fq "links: $ROOT -> $HOME" <<<"$output"
}

assert_plan Linux x86_64 linux-x86_64
assert_plan Linux aarch64 linux-arm64
assert_plan Darwin arm64 macos-arm64

if DOTFILES_OS=Darwin DOTFILES_ARCH=x86_64 "$INSTALLER" --dry-run >/dev/null 2>&1; then
  echo "macOS x86_64 should be rejected" >&2
  exit 1
fi

if DOTFILES_OS=FreeBSD DOTFILES_ARCH=x86_64 "$INSTALLER" --dry-run >/dev/null 2>&1; then
  echo "unsupported operating systems should be rejected" >&2
  exit 1
fi

echo "platform plan tests passed"
