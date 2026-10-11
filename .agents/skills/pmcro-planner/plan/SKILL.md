---
name: plan
description: Plan the minimum PMCR-O work from a seed and a plugin. Read-only.
---
# plan
## Inputs
Require the seed, the selected plugin, and only resources resolved as admissible by resource-registry-agent, or equivalent independent PASS evidence during bootstrap.
## Workflow
1. Run `scripts/plan-task.ps1` after orchestrate records invoke or goal. The before hook says `I AM the @planner /pmcro-planner:plan`, and the after hook names `@maker /pmcro-maker:make`.
2. Drop every resource that is not validated. The steps are only the validated resources, with the catalog first.
3. Invoke and goal both set the next call to `@maker /pmcro-maker:make`. Do not call skill-creator and do not issue a verdict.

## References
Call setup: [call.md](references/call.md)
## Recursive cascade contract
I AM the planner. This phase agent is itself the orchestrator of the bounded **planner domain**. It may run an inner `ORCHESTRATE -> PLAN -> MAKE -> CHECK -> REFLECT` cycle to produce its own phase product: **bare-minimum plan artifact**.

The inner cycle inherits the parent goal bounds, grant ceiling, validated-resource set, completion criteria, and governance constraints. It may narrow them but never widen them. The inner MAKE may create this phase product, but it may not **execute the target plan**.

If the inner CHECK returns LOOP or HALT, the inner REFLECT records the earned constraint and next seed. Control returns upward; the phase does not jump forward or repair outside its authority.
