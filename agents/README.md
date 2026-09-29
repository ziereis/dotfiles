# Agent contracts

Provider-neutral documents that tell coding agents how to work in this
environment. Nothing here is stowed into `$HOME`; everything is published
explicitly by `scripts/publish_agents.sh`.

## Documents

`WORKING_CONTRACT.md` is the canonical global contract: role, communication,
engineering rules, architecture grounding, investigation and verification
discipline, git and worktree hygiene, work tracking, and GitHub etiquette. It
applies to every project unless a repo-local `AGENTS.md`, `AGENTS.override.md`,
or `CLAUDE.md` adds more specific rules. Both clients load it at startup.

`REVIEW.md` is a standalone evidence-driven pull request review method: review
charter, boundary and lifetime tracing, cost accounting, falsification before
publishing, correction experiments, severity and disposition, and reusable
templates. It is a workstream rather than a pass over a diff — twelve phases,
private artifacts in `.notes/`, and code written in phase 8 — so it is reached
deliberately, never automatically.

`skills/deep-review/SKILL.md` is the entry point that makes `REVIEW.md`
reachable. Claude Code 2.1 and Codex 0.153 implement the same
`skills/<name>/SKILL.md` format with the same frontmatter keys and the same
`$ARGUMENTS` substitution, so one file serves both. It carries
`disable-model-invocation: true`, which keeps an agent from starting a
twelve-phase review on its own; you invoke it.

`skills/design-review/SKILL.md` provides a focused design review based on John
Ousterhout's *A Philosophy of Software Design* (first edition, 2018). Its bundled
`references/book-summary.md` covers all 21 chapters and numbered subsections,
all 14 named red flags, and additional design smells. It requires evidence of
complexity in real callers and changes, rather than treating principles as rigid
rules. It can be selected for design-review requests and reports findings without
editing code by default. The original PDF is not required after publication.

Invoke `/design-review path/to/code` in Claude or `$design-review path/to/code`
in Codex, or ask for a design review in natural language. With no target, it uses
uncommitted changes or the current branch's established diff base.

## Using the review method

```
/deep-review 1234          # a pull request number
/deep-review my-branch     # a branch
/deep-review path/to/dir   # a subsystem
/deep-review               # resolves the current branch's pull request
```

Identical in both clients. The skill reads `REVIEW.md` from its own directory,
which is why the method is published alongside it rather than referenced at an
absolute path.

## Publication

`scripts/publish_agents.sh` copies each source to its provider destinations:

| Source | Claude Code | Codex |
| --- | --- | --- |
| `WORKING_CONTRACT.md` | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` |
| `skills/deep-review/SKILL.md` | `~/.claude/skills/deep-review/SKILL.md` | `~/.codex/skills/deep-review/SKILL.md` |
| `REVIEW.md` | `~/.claude/skills/deep-review/REVIEW.md` | `~/.codex/skills/deep-review/REVIEW.md` |
| `skills/design-review/SKILL.md` | `~/.claude/skills/design-review/SKILL.md` | `~/.codex/skills/design-review/SKILL.md` |
| `skills/design-review/references/book-summary.md` | `~/.claude/skills/design-review/references/book-summary.md` | `~/.codex/skills/design-review/references/book-summary.md` |

Copies rather than symlinks, because the clients do not reliably follow a
symlinked contract. `install_packages.sh` runs the script after Stow.

Each successful publish records the published SHA-256 under
`~/.local/state/dotfiles/agents/`. A destination that matches neither its
current source nor the last published one is treated as yours: the script
reports it and refuses to overwrite it, matching how Stow refuses to clobber
existing files. `--force` overrides that, except for a directory in the way,
which is always an error.

```sh
./scripts/publish_agents.sh            # publish
./scripts/publish_agents.sh --check    # report drift, nonzero if any
./scripts/publish_agents.sh --dry-run  # print the plan only
./scripts/publish_agents.sh --force    # replace a hand-edited copy
```

Adding a document is one line in the script's `PUBLICATIONS` table.

## Provenance

`WORKING_CONTRACT.md` and `REVIEW.md` were taken verbatim from
[`benvanik/dotfiles`](https://github.com/benvanik/dotfiles) at commit
[`5bc0bb3`](https://github.com/benvanik/dotfiles/commit/5bc0bb3230b54ee19ab60cebe06ff5d301f7ed04)
(2026-08-19). The working contract now includes local complexity-first code style
guidance derived from Ousterhout's book; `REVIEW.md` remains unchanged. Upstream
publishes only the contract and leaves `REVIEW.md` unreferenced; both skill
entrypoints and the paraphrased book reference are local additions.
