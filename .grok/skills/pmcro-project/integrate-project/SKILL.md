---
name: integrate-project
description: "Integrate PMCR-O control, agent, host, queue, and external-domain references into an existing project; dry-run by default and apply only explicitly."
---
# integrate-project

Route: `@pmcro-agent /pmcro-project:integrate-project`.

## Contract
- Dry-run is the default: `python scripts/integrate.py --target W:\ProjectName`.
- Apply requires `--apply`.
- Preserve unknown project files and existing GitHub workflows.
- Preflight every managed file. Any differing managed path is a conflict; do not partially overwrite it.
- Materialize PMCR-O core locally, project `.agents` and host surfaces from it, and register domain agents by reference instead of copying their functionality into the project.
- The resulting project becomes a project-level orchestrator; domain-specific work still routes to independently addressable domain agents.
