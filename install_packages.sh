#!/usr/bin/env bash

set -euo pipefail

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
elif [[ $# -ne 0 ]]; then
  echo "usage: $0 [--dry-run]" >&2
  exit 2
fi

OS=${DOTFILES_OS:-$(uname -s)}
ARCH=${DOTFILES_ARCH:-$(uname -m)}

case "$OS" in
  Linux) OS=linux ;;
  Darwin) OS=macos ;;
  *) echo "unsupported operating system: $OS" >&2; exit 1 ;;
esac

case "$ARCH" in
  x86_64|amd64) ARCH=x86_64 ;;
  arm64|aarch64) ARCH=arm64 ;;
  *) echo "unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

if [[ "$OS" == macos && "$ARCH" != arm64 ]]; then
  echo "only Apple Silicon macOS is supported" >&2
  exit 1
fi

PLATFORM="$OS-$ARCH"
BIN_DIR=${BIN_DIR:-"$HOME/.local/bin"}
TMP_DIR=""

cleanup() {
  [[ -z "$TMP_DIR" ]] || rm -rf "$TMP_DIR"
}
trap cleanup EXIT

say() {
  printf '%s\n' "$*"
}

github_release_json() {
  local repo=$1
  local curl_args=(-fsSL --retry 3)
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    curl_args+=(-H "Authorization: Bearer $GITHUB_TOKEN")
    curl_args+=(-H "X-GitHub-Api-Version: 2022-11-28")
  fi
  curl "${curl_args[@]}" "https://api.github.com/repos/$repo/releases/latest"
}

install_system_packages() {
  case "$OS" in
    linux)
      local packages=(ca-certificates curl git jq unzip stow zsh fish tmux build-essential)
      say "system[apt]: ${packages[*]}"
      if (( ! DRY_RUN )); then
        command -v apt-get >/dev/null || {
          echo "Linux support currently requires Debian or Ubuntu (apt-get)." >&2
          exit 1
        }
        sudo apt-get update
        sudo apt-get install -y "${packages[@]}"
      fi
      ;;
    macos)
      local packages=(git jq stow fish tmux)
      say "system[brew]: ${packages[*]}"
      if (( ! DRY_RUN )); then
        command -v brew >/dev/null || {
          echo "Homebrew is required: https://brew.sh" >&2
          exit 1
        }
        xcode-select -p >/dev/null 2>&1 || {
          echo "Install the Xcode Command Line Tools with: xcode-select --install" >&2
          exit 1
        }
        brew install "${packages[@]}"
      fi
      ;;
  esac
}

asset_pattern() {
  local tool=$1
  case "$tool:$PLATFORM" in
    neovim:linux-x86_64) echo '^nvim-linux-x86_64\.tar\.gz$' ;;
    neovim:linux-arm64) echo '^nvim-linux-arm64\.tar\.gz$' ;;
    neovim:macos-arm64) echo '^nvim-macos-arm64\.tar\.gz$' ;;
    ripgrep:linux-x86_64) echo '^ripgrep-.*-x86_64-unknown-linux-musl\.tar\.gz$' ;;
    ripgrep:linux-arm64) echo '^ripgrep-.*-aarch64-unknown-linux-gnu\.tar\.gz$' ;;
    ripgrep:macos-arm64) echo '^ripgrep-.*-aarch64-apple-darwin\.tar\.gz$' ;;
    fzf:linux-x86_64) echo '^fzf-.*-linux_amd64\.tar\.gz$' ;;
    fzf:linux-arm64) echo '^fzf-.*-linux_arm64\.tar\.gz$' ;;
    fzf:macos-arm64) echo '^fzf-.*-darwin_arm64\.tar\.gz$' ;;
    bat:linux-x86_64) echo '^bat-v.*-x86_64-unknown-linux-gnu\.tar\.gz$' ;;
    bat:linux-arm64) echo '^bat-v.*-aarch64-unknown-linux-gnu\.tar\.gz$' ;;
    bat:macos-arm64) echo '^bat-v.*-aarch64-apple-darwin\.tar\.gz$' ;;
    delta:linux-x86_64) echo '^delta-.*-x86_64-unknown-linux-gnu\.tar\.gz$' ;;
    delta:linux-arm64) echo '^delta-.*-aarch64-unknown-linux-gnu\.tar\.gz$' ;;
    delta:macos-arm64) echo '^delta-.*-aarch64-apple-darwin\.tar\.gz$' ;;
    lazygit:linux-x86_64) echo '^lazygit_.*_linux_x86_64\.tar\.gz$' ;;
    lazygit:linux-arm64) echo '^lazygit_.*_linux_arm64\.tar\.gz$' ;;
    lazygit:macos-arm64) echo '^lazygit_.*_darwin_arm64\.tar\.gz$' ;;
    tree-sitter:linux-x86_64) echo '^tree-sitter-cli-linux-x64\.zip$' ;;
    tree-sitter:linux-arm64) echo '^tree-sitter-cli-linux-arm64\.zip$' ;;
    tree-sitter:macos-arm64) echo '^tree-sitter-cli-macos-arm64\.zip$' ;;
    ninja:linux-x86_64) echo '^ninja-linux\.zip$' ;;
    ninja:linux-arm64) echo '^ninja-linux-aarch64\.zip$' ;;
    ninja:macos-arm64) echo '^ninja-mac\.zip$' ;;
    gh:linux-x86_64) echo '^gh_.*_linux_amd64\.tar\.gz$' ;;
    gh:linux-arm64) echo '^gh_.*_linux_arm64\.tar\.gz$' ;;
    gh:macos-arm64) echo '^gh_.*_macOS_arm64\.zip$' ;;
    *) echo "no release mapping for $tool on $PLATFORM" >&2; return 1 ;;
  esac
}

install_github_binary() {
  local tool=$1 repo=$2 binary=$3 pattern json asset_count url digest archive extracted found actual
  pattern=$(asset_pattern "$tool")
  say "release[$tool]: $repo / $pattern"
  (( DRY_RUN )) && return

  json=$(github_release_json "$repo")
  asset_count=$(jq --arg pattern "$pattern" '[.assets[] | select(.name | test($pattern))] | length' <<<"$json")
  if [[ "$asset_count" != 1 ]]; then
    echo "$tool: expected one release asset matching $pattern, found $asset_count" >&2
    return 1
  fi

  url=$(jq -r --arg pattern "$pattern" '.assets[] | select(.name | test($pattern)) | .browser_download_url' <<<"$json")
  digest=$(jq -r --arg pattern "$pattern" '.assets[] | select(.name | test($pattern)) | .digest // empty' <<<"$json")
  archive="$TMP_DIR/${url##*/}"
  extracted="$TMP_DIR/$tool"
  mkdir -p "$extracted"
  curl -fL --retry 3 -o "$archive" "$url"

  if [[ "$digest" == sha256:* ]]; then
    if [[ "$OS" == macos ]]; then
      actual=$(shasum -a 256 "$archive" | awk '{print $1}')
    else
      actual=$(sha256sum "$archive" | awk '{print $1}')
    fi
    [[ "$actual" == "${digest#sha256:}" ]] || {
      echo "$tool: SHA-256 verification failed" >&2
      return 1
    }
  else
    echo "$tool: GitHub did not publish a digest for ${url##*/}" >&2
    return 1
  fi

  case "$archive" in
    *.tar.gz) tar -xzf "$archive" -C "$extracted" ;;
    *.zip) unzip -q "$archive" -d "$extracted" ;;
    *) echo "$tool: unsupported archive: ${archive##*/}" >&2; return 1 ;;
  esac

  # BSD find (macOS) does not support GNU find's -quit.
  found=$(find "$extracted" -type f -name "$binary" | sed -n '1p')
  [[ -n "$found" ]] || {
    echo "$tool: binary '$binary' not found in ${url##*/}" >&2
    return 1
  }
  install -m 0755 "$found" "$BIN_DIR/$binary"
}

install_git_checkout() {
  local repo=$1 destination=$2
  say "checkout: $repo -> $destination"
  (( DRY_RUN )) && return
  if [[ -d "$destination/.git" ]]; then
    return
  fi
  if [[ -e "$destination" ]]; then
    echo "cannot clone $repo: $destination already exists and is not a Git checkout" >&2
    return 1
  fi
  mkdir -p "${destination%/*}"
  git clone --depth 1 "$repo" "$destination"
}

say "platform: $PLATFORM"
install_system_packages

if (( ! DRY_RUN )); then
  mkdir -p "$BIN_DIR"
  TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-install.XXXXXX")
fi

install_github_binary neovim neovim/neovim nvim
install_github_binary ripgrep BurntSushi/ripgrep rg
install_github_binary fzf junegunn/fzf fzf
install_github_binary bat sharkdp/bat bat
install_github_binary delta dandavison/delta delta
install_github_binary lazygit jesseduffield/lazygit lazygit
install_github_binary tree-sitter tree-sitter/tree-sitter tree-sitter
install_github_binary ninja ninja-build/ninja ninja
install_github_binary gh cli/cli gh

install_git_checkout https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
install_git_checkout https://github.com/zsh-users/zsh-autosuggestions "$HOME/.local/share/zsh/plugins/zsh-autosuggestions"
install_git_checkout https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.local/share/zsh/plugins/zsh-syntax-highlighting"
install_git_checkout https://github.com/sindresorhus/pure "$HOME/.local/share/zsh/plugins/pure"

say "installed release binaries in $BIN_DIR"
say "Mason will install Neovim-specific language servers, formatters, and debuggers."
