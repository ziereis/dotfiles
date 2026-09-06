#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PUBLISH="$ROOT/scripts/publish_agents.sh"
WORK=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-agents-test.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

TARGET="$WORK/home"
SOURCE="$WORK/agents"
CLAUDE="$TARGET/.claude/CLAUDE.md"
CODEX="$TARGET/.codex/AGENTS.md"
CLAUDE_SKILL="$TARGET/.claude/skills/deep-review/SKILL.md"
CODEX_SKILL="$TARGET/.codex/skills/deep-review/SKILL.md"
CLAUDE_METHOD="$TARGET/.claude/skills/deep-review/REVIEW.md"
CODEX_METHOD="$TARGET/.codex/skills/deep-review/REVIEW.md"

mkdir -p "$TARGET" "$SOURCE/skills/deep-review"
printf 'contract v1\n' >"$SOURCE/WORKING_CONTRACT.md"
printf 'review method v1\n' >"$SOURCE/REVIEW.md"
printf 'skill v1\n' >"$SOURCE/skills/deep-review/SKILL.md"

publish() {
  DOTFILES_TARGET="$TARGET" DOTFILES_AGENTS_DIR="$SOURCE" "$PUBLISH" "$@"
}

fail() {
  echo "agents test: $*" >&2
  exit 1
}

# The real agents/ directory publishes to both providers, byte for byte.
DOTFILES_TARGET="$TARGET" "$PUBLISH" >/dev/null
for pair in \
    "agents/WORKING_CONTRACT.md:$CLAUDE" \
    "agents/WORKING_CONTRACT.md:$CODEX" \
    "agents/skills/deep-review/SKILL.md:$CLAUDE_SKILL" \
    "agents/skills/deep-review/SKILL.md:$CODEX_SKILL" \
    "agents/REVIEW.md:$CLAUDE_METHOD" \
    "agents/REVIEW.md:$CODEX_METHOD"; do
  cmp -s "$ROOT/${pair%%:*}" "${pair#*:}" || fail "${pair#*:} differs from ${pair%%:*}"
  [[ ! -L "${pair#*:}" ]] || fail "${pair#*:} was published as a symlink"
done
DOTFILES_TARGET="$TARGET" "$PUBLISH" --check >/dev/null || fail "--check rejected a fresh publication"

# The published skill must name the reference document that ships beside it.
grep -Fq 'REVIEW.md' "$CLAUDE_SKILL" || fail "skill does not reference REVIEW.md"

rm -rf "$TARGET"
mkdir -p "$TARGET"

# Missing destinations are reported by --check and created by a publish.
publish --check >/dev/null && fail "--check accepted missing destinations"
publish --dry-run >/dev/null
[[ ! -e "$CLAUDE" ]] || fail "--dry-run wrote a destination"
publish >/dev/null
cmp -s "$SOURCE/WORKING_CONTRACT.md" "$CLAUDE" || fail "claude contract was not created"
cmp -s "$SOURCE/skills/deep-review/SKILL.md" "$CODEX_SKILL" || fail "codex skill was not created"
cmp -s "$SOURCE/REVIEW.md" "$CODEX_METHOD" || fail "codex review method was not created"

# Republishing an unchanged source is a no-op that stays clean.
publish >/dev/null
publish --check >/dev/null || fail "--check rejected an unchanged publication"

# A new revision of any source is drift until it is republished.
printf 'skill v2\n' >"$SOURCE/skills/deep-review/SKILL.md"
publish --check >/dev/null && fail "--check missed a stale published skill"
publish >/dev/null
cmp -s "$SOURCE/skills/deep-review/SKILL.md" "$CLAUDE_SKILL" || fail "stale skill was not refreshed"
publish --check >/dev/null || fail "--check rejected the refreshed publication"

# A hand-edited destination belongs to the user until --force says otherwise.
printf 'local edits\n' >"$CLAUDE"
publish >/dev/null 2>&1 && fail "publish overwrote a hand-edited destination"
grep -q 'local edits' "$CLAUDE" || fail "hand-edited destination was modified"
publish --force >/dev/null
cmp -s "$SOURCE/WORKING_CONTRACT.md" "$CLAUDE" || fail "--force did not replace the hand-edited destination"

# A symlinked destination is refused for the same reason.
rm -f "$CODEX_SKILL"
ln -s "$SOURCE/skills/deep-review/SKILL.md" "$CODEX_SKILL"
publish >/dev/null 2>&1 && fail "publish followed a symlinked destination"
[[ -L "$CODEX_SKILL" ]] || fail "refused publish still replaced the symlink"
publish --force >/dev/null
[[ ! -L "$CODEX_SKILL" ]] || fail "--force left the symlink in place"
cmp -s "$SOURCE/skills/deep-review/SKILL.md" "$CODEX_SKILL" || fail "--force did not write a regular file"

# A directory in the way is a hard error even with --force.
rm -f "$CLAUDE"
mkdir "$CLAUDE"
publish --force >/dev/null 2>&1 && fail "--force tried to replace a directory"
[[ -d "$CLAUDE" ]] || fail "directory destination was removed"
rmdir "$CLAUDE"

# A missing source is an error rather than a silent skip.
rm -f "$SOURCE/REVIEW.md"
publish >/dev/null 2>&1 && fail "publish accepted a missing source"

echo "agent publication tests passed"
