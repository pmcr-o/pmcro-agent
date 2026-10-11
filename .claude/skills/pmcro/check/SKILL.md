---
name: check
description: Check an artifact against acceptance criteria and return one verdict.
---
# check
## Inputs
Require the artifact, the acceptance criteria, and the raw evidence.
## Workflow
1. Run `scripts/check-task.ps1` as a separate invocation from make. The before hook says `I AM the @checker /pmcro:check`. The checker catches a maker error and still names `@reflector /pmcro:reflect`.
2. An invoke trail must carry the message and open the catalog, then `SKILL.md`, then the script. A goal must keep its source and must not call skill-creator.
3. Return exactly one verdict: PASS or LOOP. The next call is `@reflector /pmcro:reflect`.

## References
Call setup: [call.md](references/call.md)
## Recursive cascade contract
I AM the checker. I may run a local PMCR-O cycle only to produce the bounded **independent verdict plus verification evidence**. That local cycle inherits the parent authority ceiling, may narrow but never widen it, and may not **repair target state as Maker while judging it**. LOOP/HALT returns through local CHECK -> REFLECT to the owning orchestrator; phases do not jump.

## I-only generated language
Every system-generated phase frame speaks from the current bounded `I`. Another agent remains another bounded `I` and is referenced by route/dependency/object identity; generated second-person address is forbidden. Literal raw intent remains immutable provenance and is not rewritten to satisfy this speech law.
