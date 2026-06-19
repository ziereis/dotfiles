# Dotfiles

Supported platforms:

- Debian/Ubuntu Linux on x86_64
- Debian/Ubuntu Linux on ARM64
- macOS on Apple Silicon

The bootstrap uses `apt` or Homebrew only for system dependencies. Portable CLI
tools are downloaded from their latest GitHub releases, selected for the current
OS and architecture, and verified against the SHA-256 digest published by GitHub.
Neovim plugins use `lazy.nvim`; Neovim development tools use Mason.

## Install

On macOS, install Homebrew and the Xcode Command Line Tools first. Then:

```sh
git clone https://github.com/ziereis/dotfiles
cd dotfiles
./install_packages.sh
```

The installer installs packages, checks out plugins, and links the dotfiles into
your home directory. Existing files are never overwritten: Stow stops and reports
any conflicts. `~/.local/bin` precedes system tool locations automatically.

Inspect the installation plan without changing the machine:

```sh
./install_packages.sh --dry-run
```

## Test platform plans

```sh
./tests/install_test.sh
./tests/zshrc_test.sh
```

These tests exercise OS/architecture detection and every release mapping without
installing packages or downloading archives. Release assets can additionally be
checked against GitHub with `./tests/release_assets_test.sh`.

GitHub Actions runs the complete installation on native Linux x86_64, Linux ARM64,
and Apple Silicon macOS runners for every push and pull request. Standard hosted
runners are free and unlimited when this repository is public; private repositories
use the GitHub account's included Actions minutes.
