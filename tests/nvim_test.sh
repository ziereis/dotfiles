#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
export XDG_CONFIG_HOME="$ROOT/.config"
export DOTFILES_CI=1

run_nvim() {
  local name=$1
  shift
  local log
  log=$(mktemp "${TMPDIR:-/tmp}/nvim-${name}.XXXXXX")
  if ! nvim --headless "$@" >"$log" 2>&1; then
    cat "$log"
    rm -f "$log"
    return 1
  fi
  if grep -E 'Error detected|Failed to (run|source)|E[0-9]{3,}:' "$log"; then
    rm -f "$log"
    return 1
  fi
  rm -f "$log"
}

# Restore exactly the commits in lazy-lock.json, then force-load every plugin so
# configuration errors cannot hide behind lazy-loading events.
run_nvim sync '+Lazy! sync' +qa
run_nvim load-all '+Lazy! load all' +qa

echo "Neovim full configuration and plugin smoke tests passed"
