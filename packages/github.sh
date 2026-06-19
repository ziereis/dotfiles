#!/usr/bin/env bash

# Ordered list of standalone tools installed from pinned GitHub releases.
GITHUB_TOOLS=(neovim ripgrep fzf bat delta lazygit tree-sitter ninja gh beads-rust)

github_repo() {
  case "$1" in
    neovim) echo neovim/neovim ;;
    ripgrep) echo BurntSushi/ripgrep ;;
    fzf) echo junegunn/fzf ;;
    bat) echo sharkdp/bat ;;
    delta) echo dandavison/delta ;;
    lazygit) echo jesseduffield/lazygit ;;
    tree-sitter) echo tree-sitter/tree-sitter ;;
    ninja) echo ninja-build/ninja ;;
    gh) echo cli/cli ;;
    beads-rust) echo Dicklesworthstone/beads_rust ;;
    *) echo "unknown GitHub tool: $1" >&2; return 1 ;;
  esac
}

github_binary() {
  case "$1" in
    neovim) echo nvim ;;
    ripgrep) echo rg ;;
    delta) echo delta ;;
    tree-sitter) echo tree-sitter ;;
    beads-rust) echo br ;;
    *) echo "$1" ;;
  esac
}

github_asset_pattern() {
  local tool=$1 platform=$2
  case "$tool:$platform" in
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
    beads-rust:linux-x86_64) echo '^br-.*-linux_amd64\.tar\.gz$' ;;
    beads-rust:linux-arm64) echo '^br-.*-linux_arm64\.tar\.gz$' ;;
    beads-rust:macos-arm64) echo '^br-.*-darwin_arm64\.tar\.gz$' ;;
    *) echo "no release mapping for $tool on $platform" >&2; return 1 ;;
  esac
}
