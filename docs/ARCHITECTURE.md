# Architecture

`pmcro-agent` is the global orchestrator and reusable runtime template. A `<domain>-agent` is a domain orchestrator. Specialized child agents are created only when they need independent state, grants, credentials, or trail ownership. Skills and scripts are executable capabilities.

Authority is one-way: host projection -> `.agents` -> `.pmcro`.

Each agent owns a local trail. Cross-agent work uses immutable handoff envelopes and receipts rather than one shared mutable trail.

## Recursive cascade

The lifecycle is self-similar. At the macro level PMCR-O moves through ORCHESTRATE -> PLAN -> MAKE -> CHECK -> REFLECT. Inside any one phase, that phase agent may orchestrate a local PMCR-O cycle to produce only its bounded phase product. Planner may locally MAKE a plan artifact but cannot execute the target plan; Checker may locally MAKE verification evidence but cannot repair the target while judging it; Reflector may MAKE a next-seed artifact but cannot execute that seed in the same cycle. Child/local cycles inherit the parent goal, grant, governance, and resource ceiling and may only narrow it.

Errors never jump phases: CHECK records PASS/LOOP/HALT, REFLECT records the earned constraint/next seed, and the owning orchestrator may admit a new cycle. Progressive disclosure bridges the scales: goal/domain at macro level -> catalog/validated resources/skill contract in the middle -> references/scripts/trail frames at micro level.
