#!/usr/bin/env bash

# Publishes the contents of agents/ to the provider-specific paths that Claude
# Code and Codex read. The clients want ordinary files there, so this copies
# rather than symlinks, and records what it published so a later run can tell
# its own copy apart from one you edited by hand.

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

AGENTS_DIR=${DOTFILES_AGENTS_DIR:-"$ROOT/agents"}
DOTFILES_TARGET=${DOTFILES_TARGET:-"$HOME"}
STATE_DIR=${DOTFILES_STATE_DIR:-"$DOTFILES_TARGET/.local/state/dotfiles/agents"}

# "source relative to agents/:destination relative to the link target". Claude
# Code and Codex share the skills/<name>/SKILL.md format, so one skill file
# serves both. Publish reference documents with their skill entrypoints.
PUBLICATIONS=(
  "WORKING_CONTRACT.md:.claude/CLAUDE.md"
  "WORKING_CONTRACT.md:.codex/AGENTS.md"
  "skills/deep-review/SKILL.md:.claude/skills/deep-review/SKILL.md"
  "skills/deep-review/SKILL.md:.codex/skills/deep-review/SKILL.md"
  "REVIEW.md:.claude/skills/deep-review/REVIEW.md"
  "REVIEW.md:.codex/skills/deep-review/REVIEW.md"
  "skills/design-review/SKILL.md:.claude/skills/design-review/SKILL.md"
  "skills/design-review/SKILL.md:.codex/skills/design-review/SKILL.md"
  "skills/design-review/references/book-summary.md:.claude/skills/design-review/references/book-summary.md"
  "skills/design-review/references/book-summary.md:.codex/skills/design-review/references/book-summary.md"
)

MODE=publish
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --check) MODE=check ;;
    --dry-run) MODE=dry-run ;;
    --force) FORCE=1 ;;
    *) echo "usage: $0 [--check|--dry-run] [--force]" >&2; exit 2 ;;
  esac
done

say() {
  printf '%s\n' "$*"
}

sha256() {
  if command -v sha256sum >/dev/null; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

# Written after every successful publish so an unrecorded or unmatched
# destination is treated as yours, not as a stale copy to be overwritten.
record_path() {
  printf '%s/%s.sha256' "$STATE_DIR" "${1//\//_}"
}

failed=0

for publication in "${PUBLICATIONS[@]}"; do
  relative_source=${publication%%:*}
  relative_destination=${publication#*:}
  source="$AGENTS_DIR/$relative_source"
  destination="$DOTFILES_TARGET/$relative_destination"

  [[ -f "$source" ]] || {
    echo "agents: source is missing: $source" >&2
    failed=1
    continue
  }
  source_sha=$(sha256 "$source")

  record=$(record_path "$relative_destination")
  published=""
  [[ -f "$record" ]] && published=$(<"$record")

  if [[ -L "$destination" ]]; then
    state=symlink
  elif [[ -e "$destination" && ! -f "$destination" ]]; then
    state=not-a-file
  elif [[ ! -e "$destination" ]]; then
    state=missing
  elif [[ "$(sha256 "$destination")" == "$source_sha" ]]; then
    state=current
  elif [[ -n "$published" && "$(sha256 "$destination")" == "$published" ]]; then
    state=stale
  else
    state=unmanaged
  fi

  # --force replaces a hand-edited file or a symlink, but never a directory.
  if (( FORCE )) && [[ "$state" == unmanaged || "$state" == symlink ]]; then
    state=stale
  fi

  case "$state" in
    current)
      say "agents[ok]: $destination"
      continue
      ;;
    missing|stale)
      if [[ "$MODE" == check ]]; then
        say "agents[$([[ $state == missing ]] && echo missing || echo drifted)]: $destination"
        failed=1
        continue
      fi
      say "agents[write]: $source -> $destination"
      [[ "$MODE" == dry-run ]] && continue
      ;;
    symlink)
      echo "agents: $destination is a symlink; remove it or rerun with --force" >&2
      failed=1
      continue
      ;;
    not-a-file)
      echo "agents: $destination exists and is not a regular file" >&2
      failed=1
      continue
      ;;
    unmanaged)
      echo "agents: $destination was not published by this repository; rerun with --force to replace it" >&2
      failed=1
      continue
      ;;
  esac

  mkdir -p "$(dirname "$destination")" "$STATE_DIR"
  staged=$(mktemp "$(dirname "$destination")/.publish-agents.XXXXXX")
  cp "$source" "$staged"
  chmod 644 "$staged"
  mv -f "$staged" "$destination"
  printf '%s\n' "$source_sha" >"$record"
done

exit "$failed"
