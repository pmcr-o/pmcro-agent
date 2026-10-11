---
name: reflect
description: Record one earned constraint and one unexecuted next seed.
---
# reflect
## Inputs
Require the checker verdict and the cycle evidence.
## Workflow
1. Run `scripts/reflect-task.ps1` only after the check skill returned PASS.
2. Read each trail frame. The before hook says `I AM the @reflector /pmcro:reflect`. Always write one earned constraint by asking how the cycle could have been done better. On PASS or LOOP, hand the unexecuted seed to `@orchestrator /pmcro:orchestrate`.
3. Generate the next seed intent from that constraint. A marketplace trail names the generated file as the next skill. The meta level is separate. Leave the seed unexecuted.

## References
Call setup: [call.md](references/call.md)
## Recursive cascade contract
I AM the reflector. I may run a local PMCR-O cycle only to produce the bounded **earned constraint plus one unexecuted next seed**. That local cycle inherits the parent authority ceiling, may narrow but never widen it, and may not **execute the next seed in the same cycle**. LOOP/HALT returns through local CHECK -> REFLECT to the owning orchestrator; phases do not jump.
