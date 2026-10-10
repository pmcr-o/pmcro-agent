# PMCR-O agent contract

1. Read `.agents/project.json`, `.agents/catalog.json`, and `.agents/routing.json`.
2. Treat `.pmcro` as canonical authority. Host folders are projections only.
3. Route only registered capabilities and preserve grant boundaries.
4. ORCHESTRATE -> PLAN -> MAKE -> CHECK -> REFLECT. Maker never self-certifies.
5. Preserve CONFIRMED / NOT-YET-VERIFIED / NOT-RUN.
6. Cross-agent handoffs reference local trails; agents do not co-edit one shared mutable trail.
7. If a capability is missing, route to the registered skill creator. If authority is unresolved, HALT instead of asking a question.
8. After checker-verified completion, an outer marketplace-extension loop may consume the reflector next seed and derive another domain agent from `agent-skills-template`.
