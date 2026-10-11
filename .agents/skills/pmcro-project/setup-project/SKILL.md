---
name: setup-project
description: "Inspect an existing project and produce a dry-run PMCR-O integration plan without changing the project."
---
# setup-project

Route: `@pmcro-agent /pmcro-project:setup-project`.

Run `python scripts/setup.py --target <project>`. This skill is read-only. It detects existing PMCR-O/host surfaces and likely domain agents, then returns the next integration route. It never installs tools or changes the target.
