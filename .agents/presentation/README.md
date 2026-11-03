# PMCR-O Output Profiles

Output profiles are provider-neutral declarations for presentation. They are not agents, skills, commands, policies, grants or reasoning strategies.

## Canonical location

- Schema: `.agents/presentation/output-profile.schema.json`
- Profiles: `.agents/presentation/profiles/*.json`
- Runtime selection: `presentationProfileRef` on an invocation context/result
- Runtime/evidence: record the selected profile reference in the relevant invocation frame under `.pmcro/`

The authored profile in `.agents/` is canonical. Claude Code, VS Code, Cursor, Codex and other host-specific files are generated projections. Do not edit generated host projections as independent sources of truth.

## Runtime behavior

The host adapter resolves a profile by ID, validates it against the schema, and supplies its presentation instructions to the invoked agent. The selected profile is inherited by child invocations unless the parent explicitly supplies a narrower/appropriate profile. A child may choose a more useful rendering profile only where the invocation contract permits it.

## Non-interference

An output profile can affect wording, verbosity, ordering, formatting and presentation sections. It cannot change:

- agent identity or lifecycle ownership;
- available tools, skills, APIs, MCP servers or grants;
- the approval policy or operator decision;
- reasoning strategy or model compute profile;
- acceptance criteria, evidence requirements or lifecycle verdict;
- whether an operation was actually executed.

The runtime must enforce these invariants independently of profile instructions. Output profile selection is not a security boundary.

## Host projections

Host adapters may use native output-style mechanisms where available. When a host has no equivalent native facility, the adapter injects the same validated profile as scoped presentation context or generated agent/rule instructions. A missing host adapter must not prevent the provider-neutral profile from remaining usable through the PMCR-O runtime API.

Do not promise identical UI controls across hosts. Promise semantic portability of the profile, then validate each host projection separately.
