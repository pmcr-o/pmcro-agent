# PMCR-O host activation

PMCR-O distinguishes **projection** from **activation**.

A projection makes the same catalog, lifecycle, grants, queue contract, agents, and skills visible to a host. Projection does **not** create authority and does **not** prove that the host entered PMCR-O.

Activation occurs only when a host-specific bootstrap instantiates a bounded I that enters through the same PMCR-O runtime.

## Universal activation law

Every supported host must preserve this path:

`host bootstrap -> host projection -> .agents -> .pmcro`

For every new root seed, the activated I must execute:

`ORCHESTRATE -> PLAN -> MAKE -> CHECK -> REFLECT`

The host must:

- read the canonical agent contract and its projected marketplace;
- preserve the immutable raw seed and lineage;
- emit `pmcro.i-context/v1` for new semantic frames;
- inherit or narrow the parent authority ceiling, never widen it;
- invoke only registered marketplace capabilities under applicable grants;
- use the same durable queue and handoff semantics;
- own a local trail rather than co-editing a shared mutable trail;
- treat model/session output as evidence until independent CHECK;
- never treat transport, subscription, model identity, or winning a competition as authority.

## Recursive composition

A host/model boundary does not create a new control plane.

A child Claude, Grok, Cursor, Codex, local-model, Actions, or future Tooensure-hosted I is another bounded I in the same lineage:

`parent I -> addressed child I -> same marketplace -> same PMCR-O lifecycle -> child evidence -> independent CHECK -> REFLECT`

Inner cycles inherit the parent authority ceiling and may narrow it. They may not widen it.

## Proof states

A projected host can be in one of three useful states:

- **PROJECTED** — PMCR-O data is visible, but no host bootstrap has been proved.
- **CANDIDATE** — a host bootstrap exists on an isolated branch/worktree and is under CHECK.
- **VALIDATED** — the bootstrap has independently demonstrated recursive PMCR-O entry, authority preservation, queue/trail semantics, and the canonical lifecycle.

Claude Code is the first proving candidate through issue #4 and branch `claude/trigger-runtime-v0`. Other hosts remain projected until equivalent evidence exists.

## Why this matters

Without this distinction, a repository can contain perfect `.claude`, `.grok`, `.cursor`, or `.github` projections while the external agent still runs an unrelated orchestration process. PMCR-O therefore validates both layers separately:

1. **projection integrity** — host files match canonical PMCR-O state;
2. **activation integrity** — the host actually enters PMCR-O as a bounded I.

Projection makes PMCR-O available. Activation makes the host participate in PMCR-O.
