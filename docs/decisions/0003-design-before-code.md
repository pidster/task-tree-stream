# 0003: Design before code

**Status:** Accepted — 2026-09-10

## Context

The project's data model is the product. A weak model cannot be patched later without migrating every plan and breaking the agent protocol. The founder requires that no code be written until the design is thorough, detailed, and well reviewed.

## Decision

No product code, build files, or dependencies are added until every design document in `docs/design/README.md` is Approved and an adversarial cross-document review is complete. Throwaway experiments that answer a design question are permitted only under `docs/research/`.

## Consequences

- Phase 1 takes longer than a prototype-first approach. We accept this for a stable model and protocol.
- Agents must refuse or escalate requests to write code before the gate, citing this ADR.
- Research experiments must be clearly disposable so they are not silently promoted to product code.

## Alternatives

- **Prototype-driven design.** Faster feedback but strong risk of the prototype becoming the product. Rejected; experiments are confined to research notes instead.
