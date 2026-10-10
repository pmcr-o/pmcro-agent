---
name: update-skill
description: Update the description of a candidate skill package. Use when a candidate needs a new purpose. Does not change the catalog.
---
# update-skill
Spoken route: `@skill-creator /skill-creator:update-skill`.

## Run
```powershell
pwsh -NoProfile -File scripts/update-skill.ps1 -Marketplace <marketplace> -Plugin <plugin> -Skill <skill> -Description "<purpose>"
```

## Workflow
1. Stop if the catalog lists the skill.
2. Update the candidate description.
3. Leave marketplace manifests and catalogs unchanged.

## References
Update rules: [package.md](references/package.md)
