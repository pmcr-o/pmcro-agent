# Orchestrate call

`scripts/setup-call.ps1` reads `.agents/catalog.json` only. The goal source is `intent`, `trail`, `catalog`, or `loop`.

| Catalog | Decision | Next |
| --- | --- | --- |
| skill is listed | invoke | `@planner /pmcro:plan` |
| skill is not listed | goal | `@planner /pmcro:plan` |

Skill-creator is present by default, with create, read, update, and delete. `call` is false. A listed route looks like `@orchestrator /dotnet:csharp-expert`.
