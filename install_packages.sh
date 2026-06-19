#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/packages/github.sh"

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
DOTFILES_TARGET=${DOTFILES_TARGET:-"$HOME"}
PRIVATE_REPO=${DOTFILES_PRIVATE_REPO:-"ziereis/dotfiles-private"}
PRIVATE_DIR=${DOTFILES_PRIVATE_DIR:-"$HOME/.local/share/dotfiles-private"}
SKIP_PRIVATE=${DOTFILES_SKIP_PRIVATE:-0}
TMP_DIR=""

cleanup() {
  [[ -z "$TMP_DIR" ]] || rm -rf "$TMP_DIR"
}
trap cleanup EXIT

say() {
  printf '%s\n' "$*"
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

install_github_binary() {
  local tool=$1 lock_line repo tag asset expected binary url archive extracted found actual
  lock_line=$(awk -F '\t' -v tool="$tool" -v platform="$PLATFORM" \
    '$1 == tool && $2 == platform { print }' "$SCRIPT_DIR/packages/github.lock")
  [[ -n "$lock_line" ]] || {
    echo "no locked release for $tool on $PLATFORM" >&2
    return 1
  }
  IFS=$'\t' read -r _ _ repo tag asset expected binary <<<"$lock_line"
  say "release[$tool]: $repo@$tag / $asset"
  (( DRY_RUN )) && return

  url="https://github.com/$repo/releases/download/$tag/$asset"
  archive="$TMP_DIR/${url##*/}"
  extracted="$TMP_DIR/$tool"
  mkdir -p "$extracted"
  curl -fL --retry 3 -o "$archive" "$url"

  if [[ "$OS" == macos ]]; then
    actual=$(shasum -a 256 "$archive" | awk '{print $1}')
  else
    actual=$(sha256sum "$archive" | awk '{print $1}')
  fi
  [[ "$actual" == "$expected" ]] || {
    echo "$tool: SHA-256 verification failed" >&2
    return 1
  }

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
  if [[ "$tool" == neovim ]]; then
    install_neovim_distribution "$found"
  else
    install -m 0755 "$found" "$BIN_DIR/$binary"
  fi
}

install_neovim_distribution() {
  local nvim_binary=$1 source_root target staged
  source_root=$(cd "$(dirname "$nvim_binary")/.." && pwd)
  target="$HOME/.local/opt/neovim"
  staged="$target.new.$$"

  mkdir -p "${target%/*}"
  rm -rf "$staged"
  mv "$source_root" "$staged"
  rm -rf "$target"
  mv "$staged" "$target"

  # Neovim needs its runtime under ../share/nvim relative to the executable.
  # Link to the complete distribution instead of copying only bin/nvim.
  rm -f "$BIN_DIR/nvim"
  ln -s "$target/bin/nvim" "$BIN_DIR/nvim"
}

install_claude() {
  local installer="$TMP_DIR/claude-install.sh"
  say "native[claude]: https://claude.ai/install.sh (stable)"
  (( DRY_RUN )) && return
  curl -fsSL --retry 3 -o "$installer" https://claude.ai/install.sh
  bash "$installer" stable
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

link_private_file() {
  local source=$1 target=$2
  if [[ -L "$target" ]]; then
    ln -sfn "$source" "$target"
  elif [[ -e "$target" ]]; then
    echo "cannot link private config: $target already exists" >&2
    echo "move its contents into $source, then remove $target and rerun" >&2
    return 1
  else
    ln -s "$source" "$target"
  fi
}

install_private_dotfiles() {
  say "private: $PRIVATE_REPO -> $PRIVATE_DIR"
  if [[ "$SKIP_PRIVATE" == 1 ]]; then
    say "private: skipped by DOTFILES_SKIP_PRIVATE"
    return
  fi
  (( DRY_RUN )) && return

  if [[ -d "$PRIVATE_DIR/.git" ]]; then
    git -C "$PRIVATE_DIR" pull --ff-only
  else
    if ! gh auth status --hostname github.com >/dev/null 2>&1; then
      if [[ -t 0 && -t 1 ]]; then
        say "GitHub authentication is required for $PRIVATE_REPO."
        gh auth login --hostname github.com --git-protocol https --web
      else
        echo "GitHub authentication is required for $PRIVATE_REPO." >&2
        echo "Run 'gh auth login', or set DOTFILES_SKIP_PRIVATE=1, then rerun." >&2
        return 1
      fi
    fi
    mkdir -p "${PRIVATE_DIR%/*}"
    gh repo clone "$PRIVATE_REPO" "$PRIVATE_DIR"
  fi

  [[ -f "$PRIVATE_DIR/zshrc.local" ]] || {
    echo "$PRIVATE_DIR/zshrc.local is missing" >&2
    return 1
  }
  [[ -f "$PRIVATE_DIR/gitconfig.local" ]] || {
    echo "$PRIVATE_DIR/gitconfig.local is missing" >&2
    return 1
  }

  mkdir -p "$DOTFILES_TARGET"
  link_private_file "$PRIVATE_DIR/zshrc.local" "$DOTFILES_TARGET/.zshrc.local"
  link_private_file "$PRIVATE_DIR/gitconfig.local" "$DOTFILES_TARGET/.gitconfig.local"
}

link_dotfiles() {
  say "links: $SCRIPT_DIR -> $DOTFILES_TARGET"
  (( DRY_RUN )) && return
  mkdir -p "$DOTFILES_TARGET"
  stow --restow --dir="$SCRIPT_DIR" --target="$DOTFILES_TARGET" .
}

say "platform: $PLATFORM"
install_system_packages

if (( ! DRY_RUN )); then
  mkdir -p "$BIN_DIR"
  TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-install.XXXXXX")
fi

for tool in "${GITHUB_TOOLS[@]}"; do
  install_github_binary "$tool"
done
install_claude

install_git_checkout https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
install_git_checkout https://github.com/zsh-users/zsh-autosuggestions "$HOME/.local/share/zsh/plugins/zsh-autosuggestions"
install_git_checkout https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.local/share/zsh/plugins/zsh-syntax-highlighting"
install_git_checkout https://github.com/sindresorhus/pure "$HOME/.local/share/zsh/plugins/pure"

install_private_dotfiles
link_dotfiles

if (( DRY_RUN )); then
  say "dry run complete"
else
  say "installed release binaries in $BIN_DIR"
  say "linked dotfiles into $DOTFILES_TARGET"
  say "Mason will install Neovim-specific language servers, formatters, and debuggers."
fi
