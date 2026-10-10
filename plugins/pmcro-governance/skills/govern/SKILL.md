---
name: govern
description: Keep PMCR-O workflow YAML separate from an ACS manifest. Refuse synthesized policy.
---
# govern
## Inputs
Require a workflow mirror. An ACS manifest is a separate host file and is not derived here.
## Workflow
1. Run scripts/reject-synthesis.ps1 on the workflow file.
2. Treat orchestrator accept or deny as intent admission. Treat ACS allow, transform, and deny as a different verdict from a real manifest.
3. Do not load a native policy runtime in this skill. A missing manifest or a missing runtime blocks execution.
4. A denial before a tool call means that tool is not invoked.
