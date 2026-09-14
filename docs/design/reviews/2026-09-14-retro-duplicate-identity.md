# Retrospective: two identity designs (D01 and D09), 2026-09-14

**Status:** Recorded 2026-09-14. Actions applied the same day; listed at the end.

## What happened

D01 (domain model) and D09 (identity, security, audit) were drafted in parallel on 2026-09-14. Both defined Organisation, Team, and User with incompatible fields, membership models, and principal kinds. The reviewer found 5 blockers in each doc traceable to the overlap, and the glossary had already recorded D09's proposed entities (Account, Membership, Grant) as settled while the escalation to add Account was still open.

## Root cause

The orchestrating agent (T1, this session) assigned two parallel authors overlapping ownership of the same concepts and relied on a later review to reconcile them.

Specifically:

1. **Both task contracts asked for identity entities.** D01's contract listed "Organisation, Team, User (as principal only; full identity model is D09)". D09's contract said "define the identity entities here and note that D01 must reference them; flag any overlap as an open question". "As principal only" is not a boundary an author can act on; both authors reasonably wrote full definitions.
2. **No document owned the concepts.** The design index recorded a dependency (D09 In Review before D01 Approved) but no ownership. A dependency says when; it does not say who defines what.
3. **Parallelism was chosen before partitioning.** The orchestrator parallelised for speed without first writing the shared interface (the identity entities and the principal model) that both docs needed. The cheap fix, a one-page identity stub written first by one author, was skipped.
4. **The glossary was writable by both authors concurrently** with no rule distinguishing decided terms from proposed ones, so the second author's proposals became apparent facts for the reviewer and the founder.
5. **The review caught it, as designed, but late.** Roughly two full T1 drafts and one T1 review were spent producing findings that a five-minute ownership decision would have prevented.

Contributing: the rules said "escalate rather than guess when a choice would change the data model", and both authors did escalate, but escalation was framed as something the reviewer or founder resolves afterwards, not something that blocks the second definition from being written.

## Why it matters

This is exactly the failure the tiered strategy (ADR 0004) is meant to avoid: expensive agents doing rework. It also weakens trust in the glossary and the index, which are the coordination surfaces for every later doc.

## Actions taken (2026-09-14)

1. `docs/design/README.md` gains a **Concept ownership map**: every domain concept has exactly one owning document; other documents reference it and never redefine it.
2. `.claude/rules/21-design-docs.md`: single-owner rule; a doc may only define concepts it owns in the ownership map; concurrent drafting of docs sharing a concept requires the owner to publish an interface stub first.
3. `.claude/rules/10-task-contract.md`: every task contract lists the concepts the task owns and the concepts it may only reference, with the owning doc. The orchestrator, not the author, is accountable for partitioning before parallelising.
4. `.claude/rules/20-docs.md`: glossary rows carry the owning doc; a term for an undecided entity is marked "proposed (Dnn, E-id)" and cannot be cited as settled by any other doc.
5. `docs/agent-rules.md` and `docs/approach.md` gain an orchestration section stating the same, so the rule survives outside Claude Code.
6. Glossary rows for Account, Membership, and Grant relabelled as proposed pending E-2026-09-14-03 and D09 review.

## Founder refinement (2026-09-14)

Independent designs of the same problem are acceptable, and sometimes desirable, as a way to validate a design. The rule therefore forbids *accidental* and *non-converging* duplication, not divergence itself. Deliberate competing designs must be declared in the ownership map with a convergence date and a synthesiser, kept in candidate files, and end in one canonical document. This should be the exception, used for high-risk concepts, not the norm.

## What the fix does not do

It does not remove the need for cross-document review. It removes one class of finding from that review so the reviewer's budget goes to real design problems.
