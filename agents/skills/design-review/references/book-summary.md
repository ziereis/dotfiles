# A Philosophy of Software Design: review reference

Source: John Ousterhout, *A Philosophy of Software Design*, first edition,
November 2018 printing (v1.01), ISBN 978-1-7321022-0-0. Based on the PDF supplied
in this dotfiles workspace. These are condensed, paraphrased review notes, not
the book's text. Section numbers follow that edition; later editions differ.
The skill works without the original PDF. Review questions and qualifications
are practical applications of the book, not additional named red flags from it.

## Navigation

- Chapters 1–3: complexity and strategic investment.
- Chapters 4–9: depth, information hiding, generality, layers, and decomposition.
- Chapters 10–11: error semantics and alternative designs.
- Chapters 12–16: comments, names, and evolution.
- Chapters 17–19: consistency, obviousness, and development practices.
- Chapters 20–21: performance and continued design improvement.
- The final checklist includes all 14 named red flags in this edition.

## Complexity lens

Ask how difficult a realistic task is for someone who did not write the code.
Look for three symptoms: **change amplification** (one decision requires edits
in many places), **cognitive load** (too much knowledge needed for a task), and
**unknown unknowns** (necessary knowledge or affected code is hard to discover).
Their underlying causes are dependencies and obscurity. Prioritize common uses
and frequently modified paths; code size alone is not a measure of complexity.

For each boundary, ask: What does it hide? What must a caller know? Can its
implementation change independently? Does removing or moving it make the whole
system simpler? Include contracts, comments, errors, and configuration in this
assessment. Apply principles with judgment, especially the book's discussions of
taking a useful idea too far.

## 1. Introduction

Design is continuous: incremental development must include revisiting earlier
decisions as understanding improves. Decompose problems so that developers can
work on parts independently, and judge designs by the complexity they remove.

- **1.1 — Using the book:** Learn through reviewing real code, recognizing red
  flags, and comparing alternatives. Principles apply to functions, classes,
  services, and other modules; none is an absolute rule.

Review cue: Is the change improving the design, or only adding behavior to a
structure everyone already struggles to understand?

## 2. The Nature of Complexity

- **2.1 — Definition:** Complexity is the effort needed to understand and change
  software. Weight it by how often developers encounter each part. Hiding
  unavoidable complexity behind a stable boundary can be nearly as useful as
  removing it.
- **2.2 — Symptoms:** Trace scattered edits, prerequisite knowledge, and
  undiscoverable dependencies. Unknown unknowns are especially dangerous because
  the developer cannot tell what must be checked.
- **2.3 — Causes:** Dependencies prevent isolated reasoning; obscurity conceals
  relevant facts. Make unavoidable dependencies explicit and simple.
- **2.4 — Accumulation:** Many individually minor shortcuts compound into a
  difficult system; scrutinize small additions of coupling too.
- **2.5 — Conclusion:** Assess the cost and risk of making changes, rather than
  the apparent simplicity of one function in isolation.

Review cue: Walk through one plausible extension and identify everything the
maintainer must discover, read, and update.

## 3. Working Code Isn't Enough

- **3.1 — Tactical programming:** Optimizing only for immediate completion leaves
  workarounds that make subsequent work harder. High output can conceal costs
  transferred to other maintainers.
- **3.2 — Strategic programming:** Invest both proactively (alternatives and
  documentation) and reactively (repairing design weaknesses as they appear).
- **3.3 — Investment size:** Prefer continual small improvements over a grand
  upfront design. The author's suggested 10–20% investment is a heuristic, not
  measured proof or a mandatory project budget.
- **3.4 — Startups:** Deadline pressure does not remove maintenance costs; the
  promise to clean everything up after growth is unreliable. The company stories
  illustrate the author's argument, not a controlled comparison.
- **3.5 — Conclusion:** Make design investment routine; repeatedly postponing it
  makes eventual repairs harder.

Review cue: Is another flag or workaround compensating for a boundary that should
change? Recommend a proportionate improvement within the actual constraints.

## 4. Modules Should Be Deep

- **4.1 — Modularity:** Separate interface from implementation so users need only
  the contract, not the internal machinery.
- **4.2 — Interfaces:** Include informal obligations such as sequencing and side
  effects, not merely declarations and types.
- **4.3 — Abstraction:** Omit irrelevant detail while preserving everything users
  need. Omitting necessary facts produces a misleading abstraction.
- **4.4 — Depth:** A small conceptual interface should provide substantial
  capability and hide significant implementation decisions.
- **4.5 — Shallowness:** An interface that costs nearly as much to learn as its
  implementation provides little relief. Some shallow modules are unavoidable.
- **4.6 — Classitis:** Creating many tiny classes or methods adds interfaces,
  navigation, and coordination costs. Length limits do not establish good design.
- **4.7 — I/O examples:** Requiring users to assemble routine infrastructure adds
  burden; make common behavior automatic and unusual choices separate.
- **4.8 — Conclusion:** Judge benefit relative to interface cost, especially for
  the common case.

Review cue: Can a caller use the module correctly from its documented interface
alone? Does a new abstraction remove more concepts than it introduces?

## 5. Information Hiding (and Leakage)

- **5.1 — Hiding:** A module should own design knowledge such as representation,
  algorithms, or protocol details. Private fields alone do not ensure this;
  accessors can expose the same knowledge indirectly.
- **5.2 — Leakage:** Shared assumptions create coupled edits even without direct
  calls. Consolidate ownership or introduce a boundary that actually hides them.
- **5.3 — Temporal decomposition:** Splitting by execution stage often duplicates
  knowledge needed at several stages. Group by knowledge ownership; sequencing
  can remain in orchestration code.
- **5.4 — HTTP example:** A protocol component should absorb request and response
  format knowledge so application code can work with meaningful operations.
- **5.5 — Too many classes:** Reading and parsing a request can share framing
  knowledge; splitting them may duplicate parsing and impose ordered calls.
- **5.6 — Parameters:** Hide encoding and storage representation. Returning an
  internal mutable map burdens callers with representation and mutation rules;
  semantic access operations can provide a stronger boundary.
- **5.7 — Defaults:** Derive routine metadata and sensible settings internally;
  common users should not have to study rare configuration options.
- **5.8 — Within a class:** Localize field access and give private helpers their
  own coherent responsibilities.
- **5.9 — Limits:** Expose information and controls users truly need, including
  relevant performance choices. Concealment is not a substitute for a contract.
- **5.10 — Conclusion:** Group knowledge rather than steps to produce deeper
  modules with fewer dependencies.

Review cue: If a file format, representation, or policy changes, how many modules
must know? Is that coupling essential, visible, and documented?

## 6. General-Purpose Modules Are Deeper

- **6.1 — Moderate generality:** Implement today's needed functionality behind an
  interface that is not tied to one particular caller. Avoid speculative features.
- **6.2 — Editor example:** A text store exposing individual UI commands couples
  storage to the editor's interactions and multiplies shallow operations.
- **6.3 — Better API:** General range insertion and deletion can express many
  editing actions through a few coherent operations.
- **6.4 — Hiding through generality:** Keep interaction policy in the UI and text
  mechanics in storage; each can evolve without importing the other's concepts.
- **6.5 — Questions:** Can fewer simple operations cover current needs? Are they
  useful in several situations? Can existing callers use them without substantial
  extra work? Fewer methods with many mode arguments may be worse.
- **6.6 — Conclusion:** Generality earns its place by simplifying current code,
  even if reuse never materializes.

Review cue: Look for one operation per caller, speculative extension hooks, or an
API so primitive that every caller must rebuild the same higher-level operation.

## 7. Different Layer, Different Abstraction

- **7.1 — Pass-through methods:** Repeated signatures and forwarding can indicate
  confused ownership. Move responsibility, expose the right component, or combine
  inseparable components when doing so simplifies the contract.
- **7.2 — Useful duplication:** Dispatchers and different implementations of one
  interface can add real behavior while preserving a signature.
- **7.3 — Decorators:** Compare added capability with forwarding boilerplate.
  Consider putting common behavior in the base, specialized behavior at its use,
  combining related decorators, or using an independent component.
- **7.4 — Interface versus implementation:** Export the user's abstraction rather
  than storage mechanics; a line-based implementation can expose text ranges.
- **7.5 — Pass-through variables:** Parameters threaded through uninvolved layers
  spread change costs. Consider appropriate shared ownership or an instance-scoped
  context, but assess hidden dependencies, mutability, and concurrency. A global
  variable or giant context bag can make the problem worse.
- **7.6 — Conclusion:** Every extra layer or interface must pay for its conceptual
  cost by removing other complexity.

Review cue: Trace one operation through its layers and state what new abstraction
each provides. Do not flag forwarding solely because its body is short.

## 8. Pull Complexity Downwards

- **8.1 — Text example:** Put splitting and joining in the text component instead
  of requiring each client to manipulate lines correctly.
- **8.2 — Configuration:** Ask whether the user can choose better than the module
  can. Compute defaults or adapt internally where possible; a knob can merely
  transfer an unresolved design decision to operators.
- **8.3 — Limits:** Absorb complexity related to the module's responsibility when
  it simplifies its interface and multiple users. Importing unrelated policy or
  creating one giant component defeats the purpose.
- **8.4 — Conclusion:** A harder implementation can be worthwhile when it makes
  the interface and the rest of the system easier.

Review cue: Are callers repeating setup, conversion, recovery, or tuning work
that the responsible module could perform once?

## 9. Better Together or Better Apart?

- **9.1 — Shared information:** Bring closely coupled knowledge together, as with
  request framing and parsing.
- **9.2 — Simpler interfaces:** Combining partial operations can remove temporary
  representations, ordering rules, and mandatory object assembly.
- **9.3 — Duplication:** Consolidate meaningful repeated logic or arrange control
  flow so it happens once. Extraction is less useful when it needs a complex
  parameter list or only replaces trivial statements.
- **9.4 — General and special code:** Separate reusable mechanisms from the policy
  of a specific application, usually placing the latter in a higher layer.
- **9.5 — Cursor and selection:** Related concepts need not share one object. A
  forced combination can add flags and indirection without simplifying clients.
- **9.6 — Logging:** One-use logging helpers may separate error context from its
  message and add interfaces without hiding useful complexity.
- **9.7 — Undo:** Separate the history mechanism, individual reversible actions,
  and policy for grouping actions. Keep each action's details with their owner.
- **9.8 — Methods:** Extract a subtask when parent and child can be understood
  independently. Split peer operations when callers benefit; retain cohesive
  sequences when splitting only forces readers or callers to reconstruct them.
- **9.9 — Conclusion:** Choose boundaries by information hiding, dependency cost,
  and interface depth, not size alone.

Review cue: What knowledge disappears from callers after the proposed split or
merge? Consider both interface and implementation costs.

## 10. Define Errors Out of Existence

- **10.1 — Cost:** Unusual control paths, partial state, cleanup, and secondary
  failures complicate reasoning and testing. This includes status codes as well
  as language exceptions.
- **10.2 — Excess errors:** Rejecting every unusual input can force widespread
  handlers without helping callers do useful recovery.
- **10.3 — Semantics:** Where suitable, define an operation by its desired result:
  ensuring absence can succeed when the object is already absent.
- **10.4 — Deletion example:** Separating removal of a name from reclamation of
  an open resource illustrates how lifecycle semantics can avoid caller errors.
- **10.5 — Range example:** An explicitly defined intersection with a range can
  remove repetitive bounds handling. That is an API choice, not permission to
  silently change an existing strict contract.
- **10.6 — Masking:** Recover internally when the module can fulfill its promise
  despite a lower-level failure. The book's retry examples are not a universal
  recommendation for indefinite retries or concealing unsuccessful operations.
- **10.7 — Aggregation:** Handle related failures at a shared recovery boundary.
  Keep error-specific knowledge at detection and response policy at handling;
  distinguish aborting a request from terminating the process.
- **10.8 — Termination:** A clear diagnostic and termination may beat fictitious
  recovery for unrecoverable failures. Suitability depends on the application,
  durability, isolation, and availability requirements.
- **10.9 — Special cases:** Choose representations whose normal operations also
  handle empty cases; an empty range may avoid a separate absence flag.
- **10.10 — Limits:** Never hide failure information needed for correct decisions.
  Catching and discarding failures does not make an operation successful.
- **10.11 — Conclusion:** Reduce the number of places needing special handling
  through semantics, real local recovery, or shared handlers.

Review cue: For each error, identify who can act on it, what state remains, and
whether simplifying handling preserves the promised outcome. Preserve necessary
input validation and diagnostics.

## 11. Design It Twice

For an important decision, sketch substantially different alternatives before
committing. Compare caller effort, interface simplicity, generality, implementation
complexity, and performance needs. Apply this to interfaces and implementations
separately. If all candidates are awkward, use their weaknesses to find another
design. The exercise develops judgment as well as improving the current choice;
it does not require two production implementations.

Review cue: Would changing the boundary or representation remove the problem
more effectively than another helper inside the existing design?

## 12. Why Write Comments? The Four Excuses

- **12.1 — Self-documenting code:** Code cannot conveniently express all semantic
  obligations and rationale. Requiring readers to infer the interface from the
  implementation defeats abstraction.
- **12.2 — Time:** Documentation is a design investment, not optional cleanup
  postponed until deadlines disappear.
- **12.3 — Staleness:** Proximity, limited duplication, and review make comments
  maintainable; possible drift is a reason to maintain them.
- **12.4 — Poor examples:** Unhelpful existing comments argue for better content,
  not for omitting missing design knowledge.
- **12.5 — Benefits:** Preserve the designer's knowledge to reduce cognitive load
  and reveal otherwise hidden dependencies.

Review cue: Can a newcomer recover the intended contract without reverse
engineering the body or consulting its original author?

## 13. Comments Should Describe Things That Aren't Obvious from the Code

- **13.1 — Conventions:** Follow project and documentation-tool conventions.
  Distinguish interface, field, implementation, and cross-module documentation.
- **13.2 — Repetition:** Restating identifiers or narrating statements adds little;
  document the information the adjacent code does not convey.
- **13.3 — Precision:** Explain units, bounds, null meanings, ownership, and
  invariants. Describe what a value represents rather than listing assignments.
- **13.4 — Intuition:** Give a higher-level purpose and mental model for a block;
  explaining how execution reaches it can clarify unusual paths.
- **13.5 — Interfaces:** State observable behavior, inputs, results, side effects,
  errors, and preconditions. Keep implementation mechanics elsewhere.
- **13.6 — Implementation:** Explain the purpose of major steps and reasons for
  surprising choices; avoid narrating obvious statements and tiny loops.
- **13.7 — Cross-module decisions:** Put shared rationale in a discoverable
  authoritative location and point to it from affected code.
- **13.8 — Conclusion:** Judge missing information from a first-time reader's
  perspective and take their confusion as evidence.
- **13.9 — Exercise answers:** Query comparison semantics belong in the contract;
  wire formats and server data structures usually do not. Performance guarantees
  may matter; failures invisible to users need no recovery-mechanism tutorial.

Review cue: Could a caller rely on the comment without opening the body? Are
necessary semantics missing while irrelevant implementation details dominate?

## 14. Choosing Names

- **14.1 — Bugs:** Similar names for logically distinct values can conceal serious
  mistakes, such as confusing a file-relative address with a physical address.
- **14.2 — Mental image:** A name should suggest the correct concept even when
  seen at a use site without surrounding declarations.
- **14.3 — Precision:** Avoid vague buckets and names narrower than actual use.
  Prefer boolean predicates. Difficulty naming can expose confused ownership
  or a variable representing too many things.
- **14.4 — Consistency:** Use one term for one concept and different terms for
  genuinely different concepts, with role qualifiers when needed.
- **14.5 — Short names:** Scope and reader familiarity matter. Short loop indices
  can work locally; greater distance from declaration usually needs more context.
  Assess reader understanding rather than enforcing brevity universally.
- **14.6 — Conclusion:** Naming is a small investment that improves comprehension
  and helps prevent incorrect assumptions.

Review cue: Would the natural interpretation of a name predict the actual value,
units, role, or behavior? Explain that mismatch rather than requesting synonyms.

## 15. Write the Comments First

- **15.1 — Delay:** Writing docs after implementation risks forgotten rationale,
  mechanical restatement, and a backlog that never gets finished.
- **15.2 — Process:** Sketch the abstraction and key method contracts, then field
  meanings, before filling in bodies. Update these as the design evolves.
- **15.3 — Design tool:** A complete but hard-to-write contract suggests interface
  complexity. Short documentation is useful evidence only if it is complete.
- **15.4 — Motivation:** Treat writing the contract as the creative act of shaping
  an abstraction, making documentation part of design rather than a chore after it.
- **15.5 — Cost:** Early revisions can save implementation rework; the author's
  estimates support an investment argument, not a guaranteed productivity ratio.
- **15.6 — Conclusion:** Try the approach and assess its effect on design clarity.

Review cue: Can the author state the complete abstraction simply, or does the
explanation require a catalogue of modes, exceptions, and unrelated purposes?

## 16. Modifying Existing Code

- **16.1 — Strategy:** Aim for a coherent design incorporating the new requirement,
  not merely the smallest diff. Balance repairs against time, compatibility, and
  migration constraints; this does not authorize an unrelated rewrite.
- **16.2 — Proximity:** Keep comments where maintainers will encounter them when
  changing the corresponding code. Narrowly scoped explanations belong near the
  relevant block; follow the project's declaration/documentation convention.
- **16.3 — Durable reasoning:** Put rationale future maintainers need in the code,
  not exclusively in commit messages.
- **16.4 — Duplication:** Maintain one authoritative explanation and references;
  link external specifications instead of copying them into comments.
- **16.5 — Diff review:** Check changed behavior against associated documentation
  and remove stale explanations or temporary development leftovers.
- **16.6 — Abstraction:** Purpose-oriented comments survive mechanical changes
  better, while semantic details still need precision.

Review cue: Does the change leave stale contracts, another special path, or a
critical explanation discoverable only in history?

## 17. Consistency

- **17.1 — Forms:** Consistent names, style, interfaces, patterns, and invariants
  let readers reuse knowledge and reduce special cases.
- **17.2 — Practice:** Document conventions, use existing automated checks, and
  consult nearby precedents. An isolated preference rarely justifies a new style;
  intentional migrations need a coherent scope.
- **17.3 — Limits:** Do not force genuinely different concepts into the same name
  or pattern. Similar appearance must imply similar behavior.
- **17.4 — Conclusion:** Small effort maintaining conventions pays off through
  more reliable reader expectations.

Review cue: Is the code unexpectedly different from its peers, or misleadingly
similar despite having different semantics?

## 18. Code Should Be Obvious

- **18.1 — Helpers:** Clear names, consistency, spacing, and targeted comments
  make structure and meaning apparent on a quick read.
- **18.2 — Obstacles:** Event callbacks obscure control flow; document triggers
  and execution context. Anonymous containers obscure field meanings; use named
  data when needed. Declared abstractions must expose relevant guarantees, and
  surprising constructor side effects or background activity need clear contracts.
  The book questions mismatched declared and allocated collection types; apply
  its underlying concern about hidden semantics, not a blanket ban on interfaces.
- **18.3 — Conclusion:** Reduce what readers must know, reuse their existing
  knowledge, and provide missing information where they need it.

Review cue: Where would a reasonable reader's first guess be wrong? Point to the
missing fact or surprising behavior and how to make it visible.

## 19. Software Trends

- **19.1 — Inheritance:** Shared interfaces can reduce learning costs.
  Implementation inheritance can couple subclasses to parent state and behavior;
  consider composition or stronger encapsulation of inherited state.
- **19.2 — Agile:** Iteration supports learning, but feature-only increments can
  encourage patches. Invest in a coherent abstraction when it becomes needed.
- **19.3 — Tests:** Confidence in behavior makes structural improvements feasible.
  Test suites support refactoring; passing tests alone do not establish good design.
- **19.4 — TDD:** The author worries that chasing the next passing test can
  displace abstraction design, while endorsing failing regression tests before bug
  fixes. Review the resulting design; do not treat test-first development itself
  as a smell or mandate a change to the team's testing process.
- **19.5 — Patterns:** Established solutions help when they fit. Pattern names
  cannot justify infrastructure that adds unnecessary complexity.
- **19.6 — Accessors:** Mechanical getters and setters can expose representation
  while giving an illusion of encapsulation. Prefer meaningful operations when
  they hide decisions; legitimate data access is not automatically a defect.
- **19.7 — Conclusion:** Evaluate practices by their effect on complexity rather
  than their popularity.

Review cue: Does a pattern solve an observed problem, or has code been distorted
to resemble a preferred pattern? Can tests protect the proposed simplification?

## 20. Designing for Performance

- **20.1 — Awareness:** Choose naturally efficient, simple designs using knowledge
  of expensive operations such as I/O, allocation, and cache misses. Avoid both
  speculative micro-optimization and widespread careless overhead. The book's
  historical timing figures are not current hardware guarantees.
- **20.2 — Measurement:** Establish a representative baseline and identify the
  actual bottleneck before optimizing. Verify improvement; additional complexity
  without demonstrated benefit is not justified.
- **20.3 — Critical path:** Prefer a fundamental algorithm or representation
  improvement. When tuning is necessary, sketch the minimum common-case work and
  design clean boundaries around it, moving exceptional work off that path.
- **20.4 — Buffers:** The RAMCloud example removes shallow layers and redundant
  checks, represents available append capacity directly, and keeps common work
  compact. It illustrates that simplification and speed can reinforce each other,
  not that the same layout is universally optimal.
- **20.5 — Conclusion:** Efficient and maintainable designs can coexist; keep
  complexity localized and justify performance tradeoffs with evidence.

Review cue: Which cost dominates on a real workload? Does the proposed change
reduce it, and are new cached values or fast-path invariants maintained correctly?

## 21. Conclusion

Practice recognizing dependencies and obscurity, explore alternative designs,
and make continual investments in clear boundaries and documentation. Good
design is a learned habit, not the result of mechanically applying a checklist.
The goal is easier future development with fewer opportunities for mistakes.

## Named red flags

All 14 named flags from this edition are listed below. These are clues requiring
context and evidence, not automatic findings. Chapter summaries above also cover
other smells: excess configuration, threaded-through parameters, unnecessary
errors, accessor exposure, inheritance coupling, surprising side effects, and
unmeasured optimization.

| Book's flag | What to investigate | Possible improvement / qualification |
| --- | --- | --- |
| Shallow Module (4, 15) | Learning the contract is nearly as hard as understanding the work it performs. | Increase useful capability behind the boundary or remove it; do not equate short code with a bad module. |
| Information Leakage (5) | Several modules encode the same representation, format, or decision and must change together. | Give the knowledge one owner with a semantic interface; private visibility alone is insufficient. |
| Temporal Decomposition (5) | Stage-based boundaries duplicate knowledge used at different times. | Group by owned knowledge; stages are fine when they genuinely encapsulate independent concerns. |
| Overexposure (5) | Routine use demands learning rare modes, choices, or setup details. | Supply defaults and separate uncommon controls without hiding necessary choices. |
| Pass-Through Method (7) | A layer mostly forwards the same contract and duplicates signature changes. | Clarify ownership, merge, or bypass the layer; verify dispatch or another useful boundary does not justify it. |
| Repetition (9) | A meaningful rule or operation is copied, creating coupled updates. | Centralize the rule or control flow; avoid abstractions based only on coincidental textual similarity. |
| Special-General Mixture (9) | A reusable mechanism knows the details of one particular application. | Move that policy to its owner and retain a useful general interface. |
| Conjoined Methods (9) | Understanding either implementation requires reading the other. | Recombine or establish a complete subtask contract; ordinary calls through a clear interface are fine. |
| Comment Repeats Code (13) | A comment adds only a prose version of the adjacent statements or name. | Replace it with missing semantics or rationale, or remove it if nothing useful is missing. |
| Implementation Documentation Contaminates Interface (13) | Caller documentation teaches internals irrelevant to correct use. | Move mechanics inside and retain observable guarantees and constraints. |
| Vague Name (14) | A name permits several plausible meanings or masks a key distinction. | Name the actual concept, role, or unit precisely enough for its scope. |
| Hard to Pick Name (14) | No concise, accurate name fits the entity. | Reconsider whether it mixes responsibilities or represents several concepts. |
| Hard to Describe (15) | A complete contract needs tangled qualifications or unrelated purposes. | Simplify the abstraction; do not merely shorten documentation and omit obligations. |
| Nonobvious Code (18) | A quick reading produces wrong expectations about behavior or meaning. | Simplify structure, expose relevant information, and explain unavoidable surprises. |

## Final review check

For each proposed finding, identify an actual reader, caller, or change scenario
that suffers; explain the dependency or obscurity; check legitimate reasons for
the current design; and compare the total complexity of the proposed alternative.
Prefer a few well-supported findings over a catalogue of ungrounded preferences.
