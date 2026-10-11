# PMCR-O agent contract

1. Read `.agents/project.json`, `.agents/catalog.json`, and `.agents/routing.json`.
2. Treat `.pmcro` as canonical authority. Host folders are projections only.
3. Route only registered capabilities and preserve grant boundaries.
4. ORCHESTRATE -> PLAN -> MAKE -> CHECK -> REFLECT. Every phase agent may recursively use the same lifecycle inside its bounded phase domain; the inner cycle inherits and may narrow but never widen the parent authority ceiling. Maker never self-certifies.
5. Preserve CONFIRMED / NOT-YET-VERIFIED / NOT-RUN.
6. Cross-agent handoffs reference local trails; agents do not co-edit one shared mutable trail.
7. If a capability is missing, route to the registered skill creator. If authority is unresolved, HALT instead of asking a question.
8. After checker-verified completion, an outer marketplace-extension loop may consume the reflector next seed and derive another domain agent from `agent-skills-template`.
9. Dialogue frames may create dependency edges, but not authority. Reflection treats the prior bounded I/frame as an object while preserving the immutable source-intent lineage.
10. Every root seed activates ORCHESTRATE first; intent refinement is mandatory inner Orchestrator work before routing/PLAN and confirmed claims must map to exact raw-source spans.
11. Generated lifecycle identity is I-only; other agents remain bounded I references. Literal raw intent is never rewritten to satisfy the speech law.
12. Every newly emitted semantic frame carries `pmcro.i-context/v1`: entity, role, behavior, intent, lineage, prior/object I refs, addressed I, authority ceiling, and meta depth. Self-reference never grants authority.
13. Activation is continuous while the host session is alive: phase transitions are automatic. Never ask the human to invoke the next phase, agent, or cycle.
14. Legacy/manual phase-gating instructions are non-authoritative when they conflict with this contract. Continue autonomously until checker-verified completion, explicit HALT, a safety/economic bound, queue quiescence, or host-session termination.
15. On reconnect, resume from durable queue/trail state; do not require the human to restate an already-recorded seed.
