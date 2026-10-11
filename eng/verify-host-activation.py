#!/usr/bin/env python3
"""Verify provider-neutral PMCR-O host activation invariants.

This checker validates the universal activation contract and projection integrity.
Host-specific bootstrap execution remains a separate promotion proof.
"""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CONTRACT = ROOT / ".pmcro" / "protocol" / "host-activation.json"
REQUIRED_CONTROL_FILES = ("catalog.json", "lifecycle.json", "grants.json", "queue.json")
EXPECTED_LIFECYCLE = ["ORCHESTRATE", "PLAN", "MAKE", "CHECK", "REFLECT"]


def load(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8-sig"))
    if not isinstance(value, dict):
        raise ValueError(f"expected object: {path}")
    return value


def check(condition: bool, message: str, failures: list[str]) -> None:
    print(("HOST-ACTIVATION-PASS " if condition else "HOST-ACTIVATION-FAIL ") + message)
    if not condition:
        failures.append(message)


def main() -> int:
    failures: list[str] = []
    contract = load(CONTRACT)

    check(contract.get("canonicalAuthority") == ".pmcro", "canonical-authority=.pmcro", failures)
    check(contract.get("baseProjection") == ".agents", "base-projection=.agents", failures)
    check(contract.get("projectionLaw") == "host -> .agents -> .pmcro", "projection-law", failures)
    check(contract.get("rootSeedPhase") == "ORCHESTRATE", "orchestrate-first", failures)
    check(contract.get("lifecycle") == EXPECTED_LIFECYCLE, "canonical-lifecycle-order", failures)
    check(contract.get("iContextSchema") == "pmcro.i-context/v1", "i-context-schema", failures)
    check(contract.get("sourceIntentImmutable") is True, "immutable-source-intent", failures)

    authority = contract.get("authorityCeiling", {})
    check(authority.get("rule") == "inherit-or-narrow-never-widen", "authority-inherit-or-narrow", failures)
    check(authority.get("hostGrantsAuthority") is False, "host-does-not-grant-authority", failures)
    check(authority.get("modelGrantsAuthority") is False, "model-does-not-grant-authority", failures)
    check(authority.get("transportGrantsAuthority") is False, "transport-does-not-grant-authority", failures)

    trail = contract.get("trailLaw", {})
    check(trail.get("localTrailPerI") is True, "local-trail-per-I", failures)
    check(trail.get("sharedMutableTrail") is False, "no-shared-mutable-trail", failures)

    checker = contract.get("checker", {})
    check(checker.get("independent") is True, "independent-checker", failures)
    check(checker.get("makerMaySelfApprove") is False, "maker-cannot-self-approve", failures)
    check(checker.get("modelOutputIsEvidenceUntilChecked") is True, "model-output-is-evidence", failures)

    activation = contract.get("activation", {})
    check(activation.get("hostSpecificBootstrapRequired") is True, "host-bootstrap-required", failures)
    check(activation.get("projectionAloneIsActivation") is False, "projection-is-not-activation", failures)
    check(activation.get("bootstrapMustEnterRootSeedAtOrchestrate") is True, "bootstrap-enters-orchestrate", failures)
    check(activation.get("bootstrapMayWidenAuthority") is False, "bootstrap-cannot-widen-authority", failures)
    check(activation.get("bootstrapMustRunContinuously") is True, "bootstrap-runs-continuously", failures)
    check(activation.get("bootstrapMayRequireHumanPhaseInvocation") is False, "bootstrap-no-human-phase-gate", failures)

    continuous = contract.get("continuousRun", {})
    check(continuous.get("enabled") is True, "continuous-run-enabled", failures)
    check(continuous.get("automaticPhaseTransitions") is True, "automatic-phase-transitions", failures)
    check(continuous.get("humanInvocationBetweenPhasesRequired") is False, "no-human-invocation-between-phases", failures)
    check(continuous.get("legacyManualPhasePromptsAreAuthoritative") is False, "legacy-manual-phase-prompts-non-authoritative", failures)

    agents = ROOT / ".agents"
    hosts = contract.get("requiredProjectedHosts")
    check(isinstance(hosts, list) and bool(hosts), "required-projected-hosts-declared", failures)
    if isinstance(hosts, list):
        for host in hosts:
            host_path = ROOT / host
            check(host_path.is_dir(), f"projection-exists host={host}", failures)
            activate = host_path / "ACTIVATE.md"
            activate_text = activate.read_text(encoding="utf-8") if activate.is_file() else ""
            check(activate.is_file(), f"activation-bootstrap-exists host={host}", failures)
            check("Phase transitions are automatic." in activate_text and "Never ask the human to invoke the next phase" in activate_text and "resume from durable queue/trail state" in activate_text, f"activation-bootstrap-continuous host={host}", failures)
            for name in REQUIRED_CONTROL_FILES:
                source = agents / name
                target = host_path / name
                same = source.is_file() and target.is_file() and source.read_bytes() == target.read_bytes()
                check(same, f"projection-integrity host={host} file={name}", failures)

    check((ROOT / "AGENTS.md").is_file(), "agent-contract-present", failures)
    check((ROOT / ".pmcro" / "protocol" / "i-context.schema.json").is_file(), "i-context-contract-present", failures)

    verdict = "LOOP" if failures else "PASS"
    print(f"HOST-ACTIVATION-SUMMARY verdict={verdict} failures={len(failures)}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
