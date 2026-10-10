---
name: delete-skill
description: Delete a candidate skill package. Use when a candidate should be removed. Refuses a skill the catalog lists.
---
# delete-skill
Spoken route: `@skill-creator /skill-creator:delete-skill`.

## Run
```powershell
pwsh -NoProfile -File scripts/delete-skill.ps1 -Marketplace <marketplace> -Plugin <plugin> -Skill <skill>
```

## Workflow
1. Stop if the catalog lists the skill.
2. Delete the candidate folder.
3. Invoke the MCP Postgres trigger `remove_skill_configuration`. It removes that skill's configuration and leaves the catalog unchanged.

## References
Delete rules: [package.md](references/package.md)
