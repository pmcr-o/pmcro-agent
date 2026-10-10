---
name: plan
description: Plan the minimum PMCR-O work from a seed and a plugin. Read-only.
---
# plan
## Inputs
Require the seed, the selected plugin, and resources the host has already validated.
## Workflow
1. Run `scripts/plan-task.ps1` after orchestrate records invoke or goal. The before hook says `I AM the @planner /pmcro:plan`, and the after hook names `@maker /pmcro:make`.
2. Drop every resource that is not validated. The steps are only the validated resources, with the catalog first.
3. Invoke and goal both set the next call to `@maker /pmcro:make`. Do not call skill-creator and do not issue a verdict.

## References
Call setup: [call.md](references/call.md)
