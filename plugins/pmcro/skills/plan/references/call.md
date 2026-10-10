# Plan call

Run `scripts/plan-task.ps1` after orchestrate. Pass `-ResourcesPath` when the host supplies resources. Every resource with `validated` false is dropped. The steps are the bare minimum: the catalog, then only the validated resources. The next call is `@maker /pmcro:make`. The plan does not call skill-creator.
