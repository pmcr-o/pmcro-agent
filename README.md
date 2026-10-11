# pmcro-agent

A reusable PMCR-O repository template and executable learning environment for bounded autonomous agent systems.

**Authority:** `.host -> .agents -> .pmcro`

**Lifecycle:** `ORCHESTRATE -> PLAN -> MAKE -> CHECK -> REFLECT`

**Autonomy:** no clarification gate. Resolve from validated context or record HALT.

**Capability law:** execute only registered + runtime-present + authorized functionality. Missing capability routes to `skill-creator-agent` and must pass an independent checker before promotion.

## Start here

- Open `docs/index.html` or the GitHub Pages site.
- Grok: `docs/tutorials/grok.md`
- Action-powered learning: `./eng/learn.ps1 -Action list` (local workflow execution delegates to `github-agent/local-actions`)
- Actions accountability: `docs/ACTIONS-ACCOUNTABILITY.md`
- Architecture: `docs/ARCHITECTURE.md`
- Thought Transfer / linguistic strange loop: `docs/THOUGHT-TRANSFER.md`
- Behavioral Intent Programming: `docs/BEHAVIORAL-INTENT-PROGRAMMING.md`
- Recursive I-context: `docs/I-AM.md`
- Extend marketplaces: `docs/MARKETPLACE-EXTENSION.md`
- Run the same real cycle manually: `eng/run-tutorial.ps1`

The repository contains a real failed cycle followed by a repaired PASS cycle under `examples/trails/` so learners can see LOOP as evidence rather than failure being hidden.

External model UI/API/local responses can be used as reasoning coprocessors through `computer-use-agent` + `model-gateway-agent`; checked repeated trails can become reusable procedures through `eval-agent`. See `docs/INFERENCE-LEARNING.md`.
