# PMCR-O Cross-Platform Agent Architecture

**Status:** Current architecture target. This improves the existing repository baseline; it does not require deleting older assets.

## 1. Separation of concerns

- PMCR-O owns lifecycle semantics, governance, laws, role contracts, evidence and trail disposition.
- Lifecycle agents own bounded role behavior and return structured results to their parent.
- Service projects are deployable API/runtime hosts for those agents.
- Microsoft Agent Framework (MAF) is the runtime substrate. Do not create a second custom agent runtime.
- O-Mode selects and applies reasoning strategies. It is a shared capability, not duplicated selector logic.
- Skills are reusable capabilities and domain knowledge, not agent identities.
- Tools, MCP and APIs are execution interfaces. A proposed call is not authorization.
- Output profiles shape presentation only.
- Marketplace manifests register and resolve packages; registration alone does not prove runtime integration.

For the current authored-genome model, `.agents/` is the source of truth. Host-specific `.claude/`, `.cursor/`, `.github/`, `.vscode/`, `.grok/` and other folders are generated projections. `.pmcro/` holds runtime state, queue state, checkpoints, approvals, trails and evidence. Do not create competing authored copies.

Keep older compatibility packages and projections while migrating. Do not delete them merely because the target model consolidates lifecycle agent identity.

## 2. Five role services

The deployment model retains one service project per lifecycle role where the solution owns those projects:

| Service | Agent identity | Responsibility |
|---|---|---|
| `ProjectName.OrchestratorService` | `@orchestrator-agent` | Parent cycle, child service routing, gates and queue dispatch |
| `ProjectName.PlannerService` | `@planner-agent` | Bounded planning; returns PlanFrame and execution intent |
| `ProjectName.MakerService` | `@maker-agent` | Executes only the authorized PlanFrame; returns artifacts and execution evidence |
| `ProjectName.CheckerService` | `@checker-agent` | Independently evaluates evidence; does not repair Maker output |
| `ProjectName.ReflectorService` | `@reflector-agent` | Records learning, limitations, earned constraints and an unexecuted next-seed proposal |

These are API/runtime deployment boundaries, not five independent marketplace plugins or five lifecycle engines. One PMCR-O lifecycle package declares the five identities and their capabilities. Each role service resolves its assigned identity and constructs/invokes it using MAF.

HTTP, gRPC or another configured transport may be used. The transport is an implementation choice; request/result schemas are the stable contract. Do not infer endpoint paths from project names.

## 3. API invocation and result

Each parent-to-child request carries:
- invocation and parent-invocation IDs;
- cycle, run, goal and lineage references;
- target `agentRef`;
- role input and context/evidence references;
- effective grant/authority ceiling and policy references;
- optional reasoning override and presentation-profile reference.

The child returns the versioned contract at `.agents/contracts/agent-invocation-result.schema.json`. The result includes:
- agent identity/status and nested trail reference;
- O-Mode strategy, family, rationale and selection reference;
- skills proposed for execution;
- proposed child-agent, service, API, tool and MCP calls;
- projected CHECK criteria and REFLECT intent;
- calls actually authorized, executed or denied;
- approval receipt and evidence references;
- disposition and summary.

**Intent is not execution.** Proposed skills/calls are an execution manifest, not an authorization grant. The parent validates every item against registered capabilities, runtime availability, argument schemas, effective grants and approval policy before dispatch. Unknown or unresolved calls fail closed.

A child returns its result to its parent; it does not co-edit the parent's trail. The parent records invocation/result/evidence references in its append-only trail. The child owns its nested trail.

## 4. Fractal lifecycle and dynamic reasoning

Each lifecycle agent independently executes a bounded internal `ORCHESTRATE -> PLAN -> MAKE -> CHECK -> REFLECT` cycle.

During its own ORCHESTRATE phase, each agent uses the shared O-Mode selector to choose a registered reasoning strategy and records the selection frame, strategy ID, family, rationale and any operator override. The selected strategy is applied through the shared capability and emits a reasoning trace.

Do not confuse:
- reasoning strategy (for example, Tree of Thoughts or ReAct);
- model compute/reasoning profile (host/model-specific effort setting);
- lifecycle phase (ORCHESTRATE, PLAN, MAKE, CHECK, REFLECT).

An explicit valid operator override takes precedence. Unsupported strategy IDs are rejected or handled by the documented selector fallback, never invented.

Planner may MAKE a PlanFrame but cannot execute its target plan. Maker may run an internal preflight CHECK but cannot self-certify. Checker gathers/evaluates evidence but does not repair the subject being checked. Reflector records a next seed but does not execute it in the same cycle. Each nested cycle inherits the parent authority ceiling and may only narrow it.

The parent trail records the invocation envelope, child result and evidence references. The child's internal frames remain in its nested trail. Escalate LOOP/HALT, policy block or unresolved decisions to the parent; do not flatten every nested frame into the parent trail.

## 5. Approval and bounded autonomy

The runtime classifies proposed calls deterministically:
- `policy-eligible`: explicitly classified bounded/reversible operations may be approved within declared scope;
- `human-required`: protected, externally visible, consequential or insufficiently classified operations require a human approval receipt;
- `prohibited`: governance policy rejects the operation;
- `unclassified`: default deny or human-required; never infer safety.

Agents may request approval but cannot grant their own authority. A receipt is bound to the exact operation/arguments (or canonical digest), resource, caller, cycle/run, policy version and expiry. It is not transferable. Recovery cannot infer or extend approval after interruption.

Human approval remains mandatory for protected actions such as granting permissions, registering or activating agents, and publishing/releasing artifacts unless accountable governance explicitly changes that policy.

## 6. Seed-intent queue

The Orchestrator may durably enqueue additional Seed Intents into the shared PMCR-O queue. Ingress first persists the raw message as intake; classification later resolves it as enqueued, informational or split. Preserve original messy-seed text and lineage.

Queue processing is bounded by idempotency/deduplication, parent/lineage references, depth limits, claim ownership, leases, heartbeats, checkpoints, inspect-before-recovery and explicit HALT conditions. A queued item is not permission to start an unlimited recursive run.

Reflector is the default owner of the next canonical Seed Intent. Orchestrator may enqueue/dispatch the Reflector's seed but must not manufacture a replacement. A next seed remains unexecuted until a later governed run claims it.

## 7. Cross-platform output profiles

Provider-neutral profiles are authored under `.agents/presentation/` and validated by `output-profile.schema.json`. An invocation selects a profile by reference; the host adapter supplies its instructions.

A profile may affect wording, verbosity, ordering and formatting. It cannot change permissions, tool availability, approvals, reasoning strategy, acceptance criteria, evidence requirements, execution facts or lifecycle verdicts. The runtime enforces this independently of prompt instructions.

Adapters may use native mechanisms where supported:
- Claude Code: selectable output-style projection where supported.
- VS Code: generated custom-agent instructions or runtime presentation context.
- Cursor: generated agent/rule instructions or runtime presentation context.
- Codex: generated scoped instructions/runtime context unless a native selector is verified.
- Other hosts: same profile contract through their adapter.

The contract is portable; native UI controls are host-specific. Do not promise an identical picker across providers.

## 8. Marketplace and projection rules

The lifecycle package contains the five agent identities and the five lifecycle skills. `@planner-agent` resolves an agent identity; `/pmcro:plan` resolves a skill. These are different namespaces.

Keep domain plugins such as .NET skills separate: PMCR-O orchestrates capabilities; .NET skills own .NET domain knowledge. Generate host-specific manifests/projections from authored declarations. Marketplace registration proves discoverability only. Runtime load tests and sealed ACCEPT evidence are needed before claiming integration.

## 9. Adoption guardrails

1. Preserve older `pmcro-agent` assets as compatibility/reference material while migrating.
2. Reuse proven O-Mode, queue, lease, checkpoint, approval and trail mechanisms.
3. Do not restore five lifecycle role plugins as five independent lifecycle systems.
4. Do not collapse the five deployable role services into an orchestrator-only service.
5. Do not claim service projects or runtime integration exist based only on this document.
6. Never mutate sealed trails. New architecture work receives new evidence.
7. Log before acting, verify before mutation, and inspect background processes/file locks before builds and MAUI operations.
