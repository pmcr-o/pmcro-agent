# Check call

Run `scripts/check-task.ps1` as a separate invocation from make. An invoke trail must open the catalog, then `SKILL.md`, then the script, and must carry the message. A goal must keep its source, must not open a skill body, and must not call skill-creator. The next call is `@reflector /pmcro:reflect`.
