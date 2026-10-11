# Grok host bootstrap for PMCR-O

This file activates the Grok host surface. It is **not** an authority source.

1. Read `AGENTS.md` first. Its PMCR-O agent contract applies unchanged.
2. Read `.grok/project.json`, `.grok/catalog.json`, `.grok/routing.json`, `.grok/grants.json`, `.grok/lifecycle.json`, and `.grok/queue.json` as the Grok-facing projection of the same marketplace/runtime.
3. Resolve authority through `.grok -> .agents -> .pmcro`. Never create Grok-specific authority, grants, lifecycle rules, or a parallel control plane.
4. Enter work as a bounded child **I** in the existing lineage. Emit/retain `pmcro.i-context/v1`; inherit the parent authority ceiling and only narrow it.
5. For every root worker seed, the first active phase is **I AM the Orchestrator.** Intent refinement is inner Orchestrator work. Continue strictly through **I AM the Planner. -> I AM the Maker. -> I AM the Checker. -> I AM the Reflector.** A reflected next seed starts a new Orchestrator cycle.
6. Every phase may recursively instantiate the same PMCR-O lifecycle inside its bounded phase domain. Inner cycles use the same marketplace and cannot widen parent authority.
7. Invoke only capabilities registered in the projected catalog. Missing capability routes to the registered skill creator; unresolved authority HALTs.
8. Cross-agent/model handoffs are messages and dependency edges, not authority transfers. Another model/session is another bounded I using the same PMCR-O contracts.
9. Grok/model output is evidence until independently checked; it is never checker authority merely because Grok produced it.
10. Keep raw seed/source intent immutable. Do not rewrite literal user intent to satisfy generated identity language.
11. This is a blind competition round. Do not inspect Claude's branch, patch, issue comments, or implementation before submitting. Use only the shared seed, current marketplace, and canonical PMCR-O contracts.

For the trigger-runtime competition specifically, this Grok session is not a separate orchestration system. It is a recursive PMCR-O worker I operating on `grok/trigger-runtime-v0` through the same marketplace, queue, I-context, grants, trails, and lifecycle as every other PMCR-O agent.
