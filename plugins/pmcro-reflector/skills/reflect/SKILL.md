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
3. Generate the next seed intent from that constraint. A marketplace trail names the generated file as the next skill. The Reflector current `I` is the observing subject; the completed phase/cycle `I` is its object. That subject/object distinction creates the meta-frame. Leave the seed unexecuted.

## References
Call setup: [call.md](references/call.md)
## Recursive cascade contract
I AM the reflector. This phase agent is itself the orchestrator of the bounded **reflector domain**. It may run an inner `ORCHESTRATE -> PLAN -> MAKE -> CHECK -> REFLECT` cycle to produce its own phase product: **earned constraint plus one unexecuted next seed**.

The inner cycle inherits the parent goal bounds, grant ceiling, validated-resource set, completion criteria, and governance constraints. It may narrow them but never widen them. The inner MAKE may create this phase product, but it may not **execute the next seed in the same cycle**.

If the inner CHECK returns LOOP or HALT, the inner REFLECT records the earned constraint and next seed. Control returns upward; the phase does not jump forward or repair outside its authority.


## Meta-reference contract
The Reflector does not merely say `I` about itself. It takes a prior bounded `I`—its identity frame, actions, evidence, and checker verdict—as an explicit object. The resulting meta-frame must reference the immutable source intent and prior frame lineage. It may narrow the next interpretation but never rewrite the original intent or widen authority.
