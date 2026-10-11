# GitHub Actions accountability in PMCR-O

PMCR-O uses GitHub Actions as an execution surface, not as an independent source of authority.

The canonical authority remains `.pmcro`. `.agents` and host folders project that authority. GitHub Actions executes repository-owned workflows and returns evidence to the same PMCR-O lifecycle.

## I-to-I lifecycle

Every checked workflow maps back to the same visible lifecycle:

1. **I AM the Orchestrator** — admit a seed and select only registered capabilities.
2. **I AM the Planner** — produce the smallest plan supported by validated resources and confirmed intent claims.
3. **I AM the Maker** — execute the bounded operation. Maker never self-approves.
4. **I AM the Checker** — independently verify artifacts, exit behavior, evidence, and semantic fidelity. Verdict is `PASS`, `LOOP`, or `HALT`.
5. **I AM the Reflector** — record the earned constraint and one unexecuted next seed. A new seed re-enters through Orchestrator.

A workflow job does not replace these identities. It is a runtime surface used by a bounded I.

## Cloud Actions and local Actions

`.github/workflows/learn.yml` is the shared workflow definition.

- **GitHub-hosted execution** runs the workflow through GitHub Actions.
- **Local execution** routes through `@github-agent /github:local-actions` and `act`.
- Both paths must preserve the same repository files, lesson semantics, PMCR-O authority, and checker evidence.
- Runtime-specific adapters may differ, but they may not change the semantic contract.

Local Actions are dry-run first. Real local workflow execution requires explicit apply authority. GitHub-hosted workflows execute only within permissions declared by the repository workflow and GitHub token policy.

## Eight evidence gates

The current learning chain is ordered and dependency-bound:

| Gate | Lesson | Evidence boundary |
| --- | --- | --- |
| 01 | Authority | `.pmcro` is canonical; projections cannot grant authority. |
| 02 | Projections | Host views resolve back to canonical control data. |
| 03 | Queue | Durable handoff preserves identity, intent lineage, digest, claim, and ACK/NACK semantics. |
| 04 | Lifecycle | `ORCHESTRATE -> PLAN -> MAKE -> CHECK -> REFLECT` remains ordered and no phase self-promotes. |
| 05 | Marketplace extension | Missing capability goes through the creator/check/promotion boundary. |
| 06 | Bounded self | `I` is an accountable operational identity with an authority ceiling, not a consciousness claim. |
| 07 | Generate action | A candidate action/capability can be generated but remains unregistered. |
| 08 | Prove action boundary | Independent evidence is required before promotion. |

A lesson unlocks only after its predecessor produces PASS evidence.

## Receipts are the learning state

PMCR-O does not treat console narration as proof. The controller records receipts that identify the lesson, runner route, verdict, workflow identity, relevant hashes/commit data, and evidence.

The important rule is:

`claim -> evidence -> independent CHECK -> receipt -> next gate`

If a workflow exits but no valid receipt exists, the lesson is not considered proven.

## Errors are fuel

A failed job is not erased. It becomes CHECK evidence.

The failure may reveal a portability defect, stale projection, invalid assumption, missing capability, or runtime-specific bug. Reflect converts that evidence into one bounded next seed. The next cycle starts again at Orchestrator.

This is why PMCR-O preserves LOOP evidence instead of treating it as noise.

## Marketplace environment

The PMCR-O organization currently exposes **25 canonical marketplace repositories**. `pmcro-agent` is the global orchestrator/template; the other repositories are independently inspectable domain or template orchestrators.

Actions should resolve work through registered marketplace capability routes rather than arbitrary hidden scripts. If functionality is missing, the system must create and independently check that capability before promotion.

## Pages

The documentation site is product evidence. Pages should publish the checked `docs/` surface, and Pages configuration belongs to the registered GitHub capability boundary rather than undocumented manual setup.

The intended chain is:

`checked repository state -> GitHub Actions validation -> Pages deployment -> public learning surface`

A successful Pages deploy never grants PMCR-O authority; it only publishes documentation generated from checked repository state.

## Next runtime layer

Once the repository/marketplace structure is stable, the same contract can receive triggers from scheduled jobs, GitHub events, a local Grok-Bot-style runner, private Claude-Code-style workspaces, and other adapters:

`event -> ORCHESTRATE -> PLAN -> MAKE -> CHECK -> REFLECT -> next event`

Trigger sources do not bypass catalog resolution, grants, local trail ownership, or independent checking.