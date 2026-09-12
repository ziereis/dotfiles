# Dotfiles

[![Cross-platform install](https://github.com/ziereis/dotfiles/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/ziereis/dotfiles/actions/workflows/ci.yml)

Supported platforms:

- Debian/Ubuntu Linux on x86_64
- Debian/Ubuntu Linux on ARM64
- macOS on Apple Silicon

The bootstrap uses `apt` or Homebrew only for system dependencies. Portable CLI
tools use releases pinned by tag, asset, and SHA-256 in `packages/github.lock`.
Normal installation never resolves GitHub's `latest` release.
This includes the `br` command from `beads_rust`. Claude Code is the exception:
it uses Anthropic's official native installer and its SHA-256 manifest
verification, and tracks the `latest` release channel. The installer passes that
channel to `claude install`, which records it as `autoUpdatesChannel` in
`~/.claude/settings.json` and so governs every later self-update. Set
`DOTFILES_CLAUDE_CHANNEL=stable` to install and pin the stable channel instead.
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

## Agent contracts

Both documents under `agents/` were taken verbatim from
[`benvanik/dotfiles`](https://github.com/benvanik/dotfiles) at commit
[`5bc0bb3`](https://github.com/benvanik/dotfiles/commit/5bc0bb3230b54ee19ab60cebe06ff5d301f7ed04)
(2026-08-19), including the copy-instead-of-symlink publication approach.

`agents/` is not stowed. `install_packages.sh` publishes it to the paths Claude
Code and Codex read:

| Source | Claude Code | Codex |
| --- | --- | --- |
| `WORKING_CONTRACT.md` | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` |
| `skills/deep-review/SKILL.md` | `~/.claude/skills/deep-review/SKILL.md` | `~/.codex/skills/deep-review/SKILL.md` |
| `REVIEW.md` | `~/.claude/skills/deep-review/REVIEW.md` | `~/.codex/skills/deep-review/REVIEW.md` |

`WORKING_CONTRACT.md` is the global contract every session loads. `REVIEW.md` is
an evidence-driven pull request review method, reached by typing `/deep-review`
in either client; both share the same `skills/<name>/SKILL.md` format, so one
skill file serves both. Publish or audit outside an install with:

```sh
./scripts/publish_agents.sh
./scripts/publish_agents.sh --check
```

Copies, not symlinks, because neither client reliably follows a symlinked
contract. A destination you edited by hand is reported and left alone until you
pass `--force`. See [`agents/README.md`](agents/README.md) for details.

## Test platform plans

```sh
./tests/install_test.sh
./tests/zshrc_test.sh
./tests/nvim_test.sh
./tests/agents_test.sh
```

These tests exercise OS/architecture detection and every release mapping without
installing packages or downloading archives. Release assets can additionally be
checked against GitHub with `./tests/release_assets_test.sh`.

GitHub Actions runs the complete installation on native Linux x86_64, Linux ARM64,
and Apple Silicon macOS runners for every push and pull request. Standard hosted
runners are free and unlimited when this repository is public; private repositories
use the GitHub account's included Actions minutes.
