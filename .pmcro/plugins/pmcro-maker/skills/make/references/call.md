# Make call

Run `scripts/make-task.ps1` after the plan. Invoke opens the routed `SKILL.md`, passes the message, then runs that skill's `scripts/validate.ps1`. A goal does not open a skill body. The next call is `@checker /pmcro:check`.
