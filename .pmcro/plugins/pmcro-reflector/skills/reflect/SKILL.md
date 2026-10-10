---
name: reflect
description: Record one earned constraint and one unexecuted next seed.
---
# reflect
## Inputs
Require the checker verdict and the cycle evidence.
## Workflow
1. Run `scripts/reflect-task.ps1` only after the check skill returned PASS.
2. Read each trail frame. The before hook and the after hook each trigger `@orchestrator /pmcro-orchestrator:orchestrate`. Always write one earned constraint by asking how the cycle could have been done better. On PASS or LOOP, hand the unexecuted seed to the orchestrator.
3. Generate the next seed intent from that constraint. A marketplace trail names the generated file as the next skill. The meta level is separate. Leave the seed unexecuted.

## References
Call setup: [call.md](references/call.md)
