# Cross-platform presentation profiles

PMCR-O output styles are provider-neutral OutputProfile declarations in `.agents/presentation/profiles/`. They are not lifecycle agents, skills, commands, policies, grants or reasoning strategies.

## Invocation

1. The caller selects a profile ID, or the runtime uses its configured default.
2. The host adapter resolves and validates the canonical profile.
3. The profile reference is added to the invocation context and recorded in the relevant `.pmcro/` trail.
4. The adapter supplies presentation instructions using the host's supported mechanism.
5. The agent returns its structured result; the runtime validates the result contract.

## Portability

The profile contract is portable; the native UI control is not guaranteed to be identical across providers. Some hosts may expose a native selectable output-style feature. Other hosts receive generated agent instructions, rules or runtime-injected presentation context. The absence of a native selector does not make a profile unavailable through the PMCR-O invocation API.

## Non-interference

Profiles can choose verbosity, audience language, section order, headings, tables and code formatting. They cannot change:
- agent identity, lifecycle ownership or available capabilities;
- permissions, grants, approvals or tool/API/MCP authorization;
- O-Mode reasoning strategy or model compute profile;
- acceptance criteria, evidence requirements or lifecycle verdict;
- whether work was actually executed.

The runtime must enforce this boundary independently of prompt instructions. Presentation profiles are not a security boundary.
