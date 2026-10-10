# Run PMCR-O from Grok

Grok is a **host projection**, not a second authority. The path is `.grok -> .agents -> .pmcro`.

## 1. Open the repository

Ask Grok to read, in order: `.grok/README.md`, `.agents/project.json`, `.agents/catalog.json`, `.agents/routing.json`, then only the selected skill body.

## 2. Seed the orchestrator

Use a seed such as: `Demonstrate one bounded PMCR-O governance capability cycle.`

Route: `@pmcro-agent /pmcro-orchestrator:orchestrate`.

The host must not invent a capability. It selects from the catalog, preserves grants, and hands work through PLAN -> MAKE -> CHECK -> REFLECT.

## 3. Same executable path from a terminal

```powershell
pwsh -NoProfile -File .pmcro/plugins/pmcro-orchestrator/skills/orchestrate/scripts/loop-cycle.ps1 `
  -Marketplace . `
  -RunId grok-tutorial-001 `
  -Source intent `
  -Goal "Demonstrate one bounded PMCR-O governance capability cycle." `
  -Plugin pmcro-governance `
  -Skill govern
```

Agent invocation and manual invocation converge on the same scripts/evidence.

## 4. Inspect the evidence

Read `.pmcro/trails/grok-tutorial-001.jsonl`, the `-check.jsonl` verdict, and `-reflect.jsonl` next seed. A LOOP is preserved; it is not rewritten as PASS.
