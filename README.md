# Dotfiles

Supported platforms:

- Debian/Ubuntu Linux on x86_64
- Debian/Ubuntu Linux on ARM64
- macOS on Apple Silicon

The bootstrap uses `apt` or Homebrew only for system dependencies. Portable CLI
tools use releases pinned by tag, asset, and SHA-256 in `packages/github.lock`.
Normal installation never resolves GitHub's `latest` release.
This includes the `br` command from `beads_rust`. Claude Code uses Anthropic's
official native installer and its SHA-256 manifest verification. Neovim plugins
use `lazy.nvim`; Neovim development tools use Mason.

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

The private companion repository `ziereis/dotfiles-private` supplies
`~/.zshrc.local` and `~/.gitconfig.local`. On a new machine, the installer opens
GitHub's browser authentication flow when `gh` is not authenticated yet. To install
only the public configuration, use:

```sh
DOTFILES_SKIP_PRIVATE=1 ./install_packages.sh
```

Update all pinned GitHub tools explicitly with:

```sh
./scripts/update_github_lock.sh
```

Review and commit the resulting lock-file changes before installing them.

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
