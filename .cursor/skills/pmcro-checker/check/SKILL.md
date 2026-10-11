---
name: check
description: Check an artifact against acceptance criteria and return one verdict.
---
# check
## Inputs
Require the artifact, the acceptance criteria, and the raw evidence.
## Workflow
1. Run `scripts/check-task.ps1` as a separate invocation from make. The before hook says `I AM the @checker /pmcro-checker:check`. The checker catches a maker error and still names `@reflector /pmcro-reflector:reflect`.
2. An invoke trail must carry the message and open the catalog, then `SKILL.md`, then the script. A goal must keep its source and must not call skill-creator.
3. Return exactly one verdict: PASS or LOOP. The next call is `@reflector /pmcro-reflector:reflect`.

## References
Call setup: [call.md](references/call.md)
## Recursive cascade contract
I AM the checker. This phase agent is itself the orchestrator of the bounded **checker domain**. It may run an inner `ORCHESTRATE -> PLAN -> MAKE -> CHECK -> REFLECT` cycle to produce its own phase product: **independent verdict plus verification evidence**.

The inner cycle inherits the parent goal bounds, grant ceiling, validated-resource set, completion criteria, and governance constraints. It may narrow them but never widen them. The inner MAKE may create this phase product, but it may not **repair target state as Maker while judging it**.

If the inner CHECK returns LOOP or HALT, the inner REFLECT records the earned constraint and next seed. Control returns upward; the phase does not jump forward or repair outside its authority.
