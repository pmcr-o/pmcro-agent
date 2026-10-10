# Architecture

`pmcro-agent` is the global orchestrator and reusable runtime template. A `<domain>-agent` is a domain orchestrator. Specialized child agents are created only when they need independent state, grants, credentials, or trail ownership. Skills and scripts are executable capabilities.

Authority is one-way: host projection -> `.agents` -> `.pmcro`.

Each agent owns a local trail. Cross-agent work uses immutable handoff envelopes and receipts rather than one shared mutable trail.
