# Ecosystem freshness

PMCR-O distinguishes **projection equality** from **source freshness**.

`eng/sync-projections.py` can prove that `.agents` and host surfaces are faithful projections of `.pmcro`, but identical projections can still carry stale marketplace-wide metadata. The canonical `.pmcro/control/ecosystem.json` therefore needs an independent freshness check against each published marketplace catalog.

`eng/verify-ecosystem-freshness.py` is deliberately a checker, not a generator. It:

- reads the canonical ecosystem declaration;
- reads the local `pmcro-agent` catalog;
- independently reads each other public marketplace's `.agents/catalog.json`;
- compares declared skill counts with observed catalog skill counts;
- reports `PASS` only when every observation matches;
- reports `LOOP` on drift, malformed catalogs, duplicate IDs, or unreadable evidence;
- never writes authority, projections, catalogs, or marketplace state.

The network path defaults to public `pmcr-o/<agent>/main/.agents/catalog.json`. `--offline-root` supports the same comparison against sibling repository fixtures without changing semantics.

A freshness failure is not repaired by editing generated documentation or host projections. The owning marketplace/catalog source must be regenerated first, then projections and documentation may be refreshed through their normal paths.

## Known proving case

At introduction time, the public `github-agent` catalog contains 10 skills while the global ecosystem declaration still records 9. The freshness workflow is expected to report `LOOP` until canonical marketplace regeneration repairs that source drift. That failure is the proof that this guard catches a class of defect the existing byte-equality projection checks cannot detect.
