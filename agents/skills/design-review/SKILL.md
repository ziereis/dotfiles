---
name: design-review
description: Review code, changes, or proposed APIs for software design complexity using John Ousterhout's A Philosophy of Software Design. Use for design reviews, abstraction and module boundary critiques, or identifying design smells and refactoring opportunities. Not a substitute for a correctness, security, or performance audit.
---

# Design Review

Review the user's requested code, diff, subsystem, or design proposal. If no
target is given, use the current uncommitted changes, then the current branch's
diff against its established base. State the scope; ask for a target if neither
provides one. Do not guess a comparison branch when the base is ambiguous.

## Method

1. Read the local project instructions and the target, including representative
   callers, interfaces, implementations, and relevant tests. For a proposal,
   distinguish stated requirements from assumptions and unimplemented behavior.
2. Read the **Complexity lens** and **Named red flags** in
   [the book reference](references/book-summary.md). Consult the numbered chapter
   summaries relevant to the target; for a broad design review, cover all chapters.
3. Trace what knowledge each module owns, what its callers must know, and what
   must change together. Count informal obligations (ordering, ownership, errors,
   configuration, side effects) as part of an interface, not just its signature.
4. Test suspected smells against real uses. Identify the concrete change
   amplification, cognitive load, or hidden dependency they cause. Check whether
   a boundary serves a purpose such as dispatch, compatibility, isolation, or
   independent policy before recommending its removal.
5. For consequential findings, compare the current design with a materially
   different alternative. Describe which knowledge or responsibility moves,
   what callers become simpler, and the migration cost or tradeoff. Sketches
   suffice; a review does not require implementing two designs.

Treat red flags as investigation prompts, not automatic defects. Optimize total
system complexity, not line counts, class counts, or stylistic conformity. A
long cohesive method can be appropriate; a short wrapper can have a useful
contract. Do not prescribe speculative frameworks, global context objects, or
rewrites merely to satisfy a principle. Apply the book's error-handling advice
only when the proposed semantics preserve required failure visibility and
recovery. Do not infer speedups without measurements.

## Deliverable

Lead with actionable findings, ordered by impact. Each finding should include:

- A precise file/line or proposal-section reference and a concise problem title.
- Evidence: affected caller or change scenario, the leaked knowledge or reader
  burden, and its consequence. Distinguish observed facts from assumptions.
- The relevant red flag or chapter and a concrete simplification, including its
  main tradeoff. Combine symptoms with the same underlying cause.

Separate behavior defects from maintainability recommendations. Use the project's
severity convention when one exists; avoid presenting taste as a blocking issue.
Finish with a short assessment, any effective design choices worth preserving,
and coverage limits or questions that could change the findings. If there are no
supported findings, say so; do not manufacture issues to fill the checklist.

Review and report by default. Edit code only when requested; do not publish
review comments to an external service without the user's instruction. This
skill stands alone and does not automatically start the separate deep-review
workflow.
