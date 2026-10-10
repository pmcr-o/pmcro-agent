---
name: orchestrate
description: Accept or deny a seed, then route a bounded cycle through registered plugin capabilities.
---
# orchestrate
## Inputs
Require seed, plugin, workspace, grantRefs, and bounds. The field name is plugin. A catalogRef field is rejected.
Preserve seed.raw_intent verbatim.
Default bounds: 12 delegated calls, one repair, child depth 1.
## Workflow
1. Run `scripts/setup-call.ps1`. The goal source is `intent`, `trail`, `catalog`, or `loop`. A trail source may be the whole prior cycle as `meta`, `meta meta`, or `meta meta meta`. The before hook says `I AM the @orchestrator /pmcro-orchestrator:orchestrate`, and the after hook names `@planner /pmcro-planner:plan`.
2. When the catalog lists the skill, invoke it with the message at `@orchestrator /<plugin>:<skill>`. The next call is `@planner /pmcro-planner:plan`.
3. Otherwise keep the goal on the cycle. A marketplace trail logs each folder as an orchestrator and each file in it as a subagent. Skill-creator already exists, with create, read, update, and delete, so the cycle does not call it.
4. Keep plan, make, check, and reflect as separate invocations.
5. On LOOP, allow one repair. On HALT, stop. On PASS, reflect.
6. Reflect returns the next goal and leaves it unexecuted.

## References
Call setup: [call.md](references/call.md)
