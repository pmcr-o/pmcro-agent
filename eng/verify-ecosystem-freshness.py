#!/usr/bin/env python3
"""Independently verify PMCR-O ecosystem skill counts against marketplace catalogs.

This checker is intentionally read-only. It does not generate or repair ecosystem.json;
it only compares the canonical declaration with independently readable marketplace catalogs.
"""

from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class Observation:
    agent_id: str
    declared: int
    observed: int | None
    source: str
    error: str | None = None

    @property
    def ok(self) -> bool:
        return self.error is None and self.observed == self.declared


def read_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8-sig") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"expected JSON object: {path}")
    return value


def count_skills(catalog: dict[str, Any], source: str) -> int:
    skills = catalog.get("skills")
    if not isinstance(skills, list):
        raise ValueError(f"catalog has no skills array: {source}")
    ids: list[str] = []
    for index, row in enumerate(skills):
        if not isinstance(row, dict) or not isinstance(row.get("id"), str):
            raise ValueError(f"catalog skill #{index} has no string id: {source}")
        ids.append(row["id"])
    if len(ids) != len(set(ids)):
        raise ValueError(f"catalog contains duplicate skill ids: {source}")
    return len(ids)


def fetch_json(url: str, timeout: float) -> dict[str, Any]:
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "pmcro-ecosystem-freshness-check/1"},
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        payload = response.read().decode("utf-8-sig")
    value = json.loads(payload)
    if not isinstance(value, dict):
        raise ValueError(f"expected JSON object: {url}")
    return value


def public_catalog_url(owner: str, agent_id: str, ref: str) -> str:
    return (
        f"https://raw.githubusercontent.com/{owner}/{agent_id}/"
        f"{ref}/.agents/catalog.json"
    )


def observe_agent(
    *,
    repo_root: Path,
    offline_root: Path | None,
    owner: str,
    ref: str,
    timeout: float,
    agent_id: str,
    declared: int,
) -> Observation:
    try:
        if agent_id == "pmcro-agent":
            path = repo_root / ".pmcro" / "control" / "catalog.json"
            observed = count_skills(read_json(path), str(path))
            return Observation(agent_id, declared, observed, str(path))

        if offline_root is not None:
            path = offline_root / agent_id / ".agents" / "catalog.json"
            observed = count_skills(read_json(path), str(path))
            return Observation(agent_id, declared, observed, str(path))

        url = public_catalog_url(owner, agent_id, ref)
        observed = count_skills(fetch_json(url, timeout), url)
        return Observation(agent_id, declared, observed, url)
    except (OSError, ValueError, json.JSONDecodeError, urllib.error.URLError) as exc:
        return Observation(agent_id, declared, None, locals().get("url", locals().get("path", agent_id)).__str__(), str(exc))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Verify ecosystem skill counts against independent marketplace catalogs."
    )
    parser.add_argument(
        "--ecosystem",
        default=".pmcro/control/ecosystem.json",
        help="Path to canonical ecosystem JSON relative to repository root.",
    )
    parser.add_argument("--owner", default="pmcr-o", help="GitHub organization/owner.")
    parser.add_argument("--ref", default="main", help="Marketplace Git ref to inspect.")
    parser.add_argument("--timeout", type=float, default=15.0, help="Per-request timeout seconds.")
    parser.add_argument(
        "--offline-root",
        type=Path,
        help="Optional directory containing sibling marketplace repos for network-free verification.",
    )
    parser.add_argument("--json", action="store_true", help="Emit machine-readable observations.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_root = Path(__file__).resolve().parents[1]
    ecosystem_path = repo_root / args.ecosystem

    try:
        ecosystem = read_json(ecosystem_path)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"ECOSYSTEM-FRESHNESS-FAIL ecosystem={ecosystem_path} error={exc}")
        return 2

    agents = ecosystem.get("agents")
    if not isinstance(agents, list) or not agents:
        print(f"ECOSYSTEM-FRESHNESS-FAIL ecosystem={ecosystem_path} error=missing-agents")
        return 2

    observations: list[Observation] = []
    seen: set[str] = set()
    structural_errors: list[str] = []

    for index, row in enumerate(agents):
        if not isinstance(row, dict):
            structural_errors.append(f"agent #{index} is not an object")
            continue
        agent_id = row.get("id")
        declared = row.get("skills")
        if not isinstance(agent_id, str) or not agent_id:
            structural_errors.append(f"agent #{index} has no string id")
            continue
        if agent_id in seen:
            structural_errors.append(f"duplicate agent id: {agent_id}")
            continue
        seen.add(agent_id)
        if not isinstance(declared, int) or isinstance(declared, bool) or declared < 0:
            structural_errors.append(f"agent {agent_id} has invalid skills count: {declared!r}")
            continue
        observations.append(
            observe_agent(
                repo_root=repo_root,
                offline_root=args.offline_root,
                owner=args.owner,
                ref=args.ref,
                timeout=args.timeout,
                agent_id=agent_id,
                declared=declared,
            )
        )

    if args.json:
        print(
            json.dumps(
                {
                    "schema": "pmcro.ecosystem-freshness-check/v1",
                    "ecosystem": str(ecosystem_path),
                    "owner": args.owner,
                    "ref": args.ref,
                    "observations": [
                        {
                            "agentId": item.agent_id,
                            "declared": item.declared,
                            "observed": item.observed,
                            "source": item.source,
                            "ok": item.ok,
                            "error": item.error,
                        }
                        for item in observations
                    ],
                    "structuralErrors": structural_errors,
                },
                indent=2,
            )
        )
    else:
        for error in structural_errors:
            print(f"ECOSYSTEM-FRESHNESS-FAIL structural={error}")
        for item in observations:
            if item.error:
                print(
                    f"ECOSYSTEM-FRESHNESS-FAIL agent={item.agent_id} "
                    f"declared={item.declared} source={item.source} error={item.error}"
                )
            elif item.observed != item.declared:
                print(
                    f"ECOSYSTEM-FRESHNESS-FAIL agent={item.agent_id} "
                    f"declared={item.declared} observed={item.observed} source={item.source}"
                )
            else:
                print(
                    f"ECOSYSTEM-FRESHNESS-PASS agent={item.agent_id} "
                    f"skills={item.observed} source={item.source}"
                )

    failures = structural_errors or [item for item in observations if not item.ok]
    if failures:
        failed_count = len(structural_errors) + sum(not item.ok for item in observations)
        print(
            f"ECOSYSTEM-FRESHNESS-SUMMARY verdict=LOOP "
            f"agents={len(observations)} failures={failed_count}"
        )
        return 1

    print(
        f"ECOSYSTEM-FRESHNESS-SUMMARY verdict=PASS "
        f"agents={len(observations)} failures=0"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
