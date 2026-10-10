---
name: create-skill
description: Create a candidate marketplace skill package with an agent, scripts, references, assets, and tests. Use when a marketplace needs a new skill. Does not register the candidate.
---
# create-skill
Spoken route: `@skill-creator /skill-creator:create-skill`.

## Run
Execute the script. Do not write the package by hand.

```powershell
pwsh -NoProfile -File scripts/create-skill.ps1 -Marketplace <marketplace> -Plugin <plugin> -Skill <skill> -Agent <agent> -Description "<purpose>"
```

## Workflow
1. Confirm the skill folder is absent. Stop if it already exists.
2. Run the script. It writes `SKILL.md`, `agents/`, `scripts/validate.ps1`, `references/package.md`, `assets/request.json`, and `tests/fixture.json`.
3. Leave marketplace manifests and catalogs unchanged. Registration waits for an independent check and a separate grant.

## Validation
`scripts/validate.ps1` exits 0 on this skill. The candidate's own `scripts/validate.ps1` exits 0 before the script returns.

## References
Package shape: [package.md](references/package.md)
Example request: [request.json](assets/request.json)
