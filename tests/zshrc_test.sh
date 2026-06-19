#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TEST_HOME=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-zsh-test.XXXXXX")
SYSTEM_BIN="$TEST_HOME/system-bin"
trap 'rm -rf "$TEST_HOME"' EXIT

mkdir -p "$TEST_HOME/.local/bin" "$SYSTEM_BIN"
ln -s /usr/bin/true "$TEST_HOME/.local/bin/rg"
ln -s /usr/bin/false "$SYSTEM_BIN/rg"

HOME="$TEST_HOME" PATH="$SYSTEM_BIN:/usr/bin:/bin" DOTFILES_ROOT="$ROOT" zsh -f -c '
  source "$DOTFILES_ROOT/.zshrc"
  [[ "$path[1]" == "$HOME/.local/bin" ]]
  [[ "$(command -v rg)" == "$HOME/.local/bin/rg" ]]
  source "$DOTFILES_ROOT/.zshrc"
  [[ ${path[(I)$HOME/.local/bin]} -eq 1 ]]
'

echo "zsh startup and PATH precedence tests passed"
