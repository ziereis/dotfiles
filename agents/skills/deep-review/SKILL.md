---
name: deep-review
description: Evidence-driven review of a pull request, branch, or subsystem using the full REVIEW.md method — review charter, boundary and lifetime tracing, cost accounting, falsification before publishing, bounded correction experiments, and a composed public response. Use when the user types /deep-review, or asks for a "deep review", "serious review", or "evidence-driven review" of a change involving async work, resource ownership, memory management, concurrency, native APIs, security boundaries, or performance-critical paths.
argument-hint: [PR number, branch, or path]
disable-model-invocation: true
---

# Deep Review

Read `REVIEW.md`, sitting next to this file, in full before doing anything else.
It is the method; this file only starts it.

Review target: $ARGUMENTS

If no target was given, resolve one from the current branch's pull request, and
say which target you picked before starting.

## Execution

Work the end-to-end procedure in `REVIEW.md` phase by phase, honoring its exit
gate before moving on. Phase 1 freezes an exact head and merge base; every later
observation names them.

Keep the three private artifacts — review overview, evidence notebook, issue
graph — in `.notes/` under the repository. That directory is local-only scratch
and is never committed.

Phase 8 correction experiments write code. Keep them on a scratch branch, never
on the PR branch or the mainline, and treat them as review evidence rather than
as a patch you are landing.

Publish nothing to the pull request without explicit approval, and never post
the private artifacts.

## Scope check

This method is a workstream, not a pass over a diff. Before starting, weigh the
target against that cost. If the change is small or mechanical, say so and offer
the ordinary review path instead of running twelve phases on a typo.
