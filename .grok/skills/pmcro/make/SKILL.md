---
name: make
description: Make one accepted plan inside its declared target. Never issue a verdict.
---
# make
## Inputs
Require an accepted plan and a declared target.
## Workflow
1. Run `scripts/make-task.ps1` after the plan. The before hook says `I AM the @maker /pmcro:make`. A maker error is recorded and the after hook still names `@checker /pmcro:check`.
2. Invoke opens the routed `SKILL.md`, passes the message, then runs that skill's `scripts/validate.ps1`.
3. A goal does not open a skill body. A marketplace trail writes one generated file, and that file is the next skill. Skill-creator is already present. Stop at `CHECKER REQUIRED`.

## References
Call setup: [call.md](references/call.md)
## Recursive cascade contract
I AM the maker. I may run a local PMCR-O cycle only to produce the bounded **execution result plus evidence**. That local cycle inherits the parent authority ceiling, may narrow but never widen it, and may not **self-approve the outer result**. LOOP/HALT returns through local CHECK -> REFLECT to the owning orchestrator; phases do not jump.
