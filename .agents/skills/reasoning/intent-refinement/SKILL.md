---
name: intent-refinement
description: "Mandatory Orchestrator-owned refinement of a raw PMCR-O seed into exact-source-grounded validated intent claims after ORCHESTRATE activates and before admission/routing/PLAN."
---
# intent-refinement
Spoken route: `@intent-refinement-agent /reasoning:intent-refinement`.

## Product
A `pmcro.intent-refinement/v1` artifact. The raw seed remains immutable. The active Orchestrator derives a working intent from only the portions it can validate.

## Invocation invariant
A new root seed first activates ORCHESTRATE. This skill is bounded inner work of that Orchestrator and every valid artifact declares `ownerPhase: ORCHESTRATE` and `invokedBy: orchestrator`. It is never a pre-orchestrator phase.

## Validated-understanding law
- `validatedClaims[]` are the only semantic claims about user intent that PLAN may treat as validated.
- Every validated claim contains exact `sourceStart`, `sourceEnd`, and `sourceExcerpt`; the excerpt must equal that slice of `rawIntent`.
- `unresolvedFragments[]` stay unresolved. Do not invent missing meaning just to make the seed grammatical.
- Spelling/speech-to-text cleanup may clarify presentation only when the interpretation remains supported by the raw source.
- Implementation hypotheses belong in `assumptions` or later validated planning resources; they are not user intent merely because they sound reasonable.

## Workflow
1. Preserve `rawIntent` byte-for-byte.
2. Decompose only the meaning that can be source-grounded into `validatedClaims[]`.
3. Record unresolved fragments separately.
4. Produce the smallest `workingIntent` that summarizes the validated claims without importing assumptions.
5. Never grant authority or execute target work.
6. Never claim hidden thought/private chain-of-thought.
7. The original seed remains the lineage root for Thought Transfer and Behavioral Intent Programming.

## Composition
`prompting-strategy-selection` may choose how an LLM performs refinement. `dialogic-awareness` may render challenge/refinement frames. Neither changes Orchestrator ownership or the source-grounding rule.

## Validation
Use `scripts/operate.py validate --input <intent.json>` and `scripts/validate.ps1`.
