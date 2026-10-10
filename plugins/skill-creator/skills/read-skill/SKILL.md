---
name: read-skill
description: Retrieve a skill from the catalog, or from a candidate package. Use to read a skill. Does not register the candidate.
---
# read-skill
Spoken route: `@skill-creator /skill-creator:read-skill`.

## Run
```powershell
pwsh -NoProfile -File scripts/read-skill.ps1 -Marketplace <marketplace> -Plugin <plugin> -Skill <skill>
```
Add `-Body` only when the route needs the skill body.

## Workflow
1. Read the catalog entry when the skill is listed.
2. Read the candidate package when it is not listed.
3. Leave marketplace manifests and catalogs unchanged.

## References
Retrieve rules: [package.md](references/package.md)
