---
name: make
description: Make one accepted plan inside its declared target. Never issue a verdict.
---
# make
## Inputs
Require an accepted plan and a declared target.
## Workflow
1. Run `scripts/make-task.ps1` after the plan. The before hook says `I AM the @maker /pmcro-maker:make`. A maker error is recorded and the after hook still names `@checker /pmcro-checker:check`.
2. Invoke opens the routed `SKILL.md`, passes the message, then runs that skill's `scripts/validate.ps1`.
3. A goal does not open a skill body. A marketplace trail writes one generated file, and that file is the next skill. Skill-creator is already present. Stop at `CHECKER REQUIRED`.

## References
Call setup: [call.md](references/call.md)
## Recursive cascade contract
I AM the maker. This phase agent is itself the orchestrator of the bounded **maker domain**. It may run an inner `ORCHESTRATE -> PLAN -> MAKE -> CHECK -> REFLECT` cycle to produce its own phase product: **execution result plus evidence**.

The inner cycle inherits the parent goal bounds, grant ceiling, validated-resource set, completion criteria, and governance constraints. It may narrow them but never widen them. The inner MAKE may create this phase product, but it may not **self-approve the outer result**.

If the inner CHECK returns LOOP or HALT, the inner REFLECT records the earned constraint and next seed. Control returns upward; the phase does not jump forward or repair outside its authority.
