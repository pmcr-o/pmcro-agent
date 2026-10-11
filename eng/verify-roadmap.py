#!/usr/bin/env python3
"""Verify PMCR-O roadmap structure and print currently selectable work.

This checker is deliberately non-authoritative: it validates roadmap consistency and
computes which tracks are dependency-unblocked. It never grants execution authority.
"""
from __future__ import annotations

import json
from pathlib import Path
from datetime import date

ROOT = Path(__file__).resolve().parents[1]
ROADMAP = ROOT / ".pmcro" / "control" / "roadmap.json"


def fail(message: str) -> None:
    raise SystemExit(f"ROADMAP-FAIL: {message}")


data = json.loads(ROADMAP.read_text(encoding="utf-8"))
if data.get("schema") != "pmcro.roadmap/v1":
    fail("unsupported schema")

allowed = set(data.get("statusValues", []))
required_statuses = {"BACKLOG", "READY", "ACTIVE", "WAITING", "LOOP", "HALT", "PASS"}
if allowed != required_statuses:
    fail("statusValues must be the canonical seven-state set")

tracks = data.get("tracks")
if not isinstance(tracks, list) or not tracks:
    fail("tracks must be a non-empty list")

by_id: dict[str, dict] = {}
for track in tracks:
    tid = track.get("id")
    if not isinstance(tid, str) or not tid:
        fail("every track needs a non-empty id")
    if tid in by_id:
        fail(f"duplicate track id: {tid}")
    by_id[tid] = track
    if track.get("status") not in allowed:
        fail(f"{tid}: invalid status {track.get('status')!r}")
    if not isinstance(track.get("priority"), int) or track["priority"] < 0:
        fail(f"{tid}: priority must be a non-negative integer")
    try:
        date.fromisoformat(track.get("targetDate", ""))
    except ValueError:
        fail(f"{tid}: targetDate must be YYYY-MM-DD")
    for field in ("intent", "ownerSurface", "nextSeed"):
        if not isinstance(track.get(field), str) or not track[field].strip():
            fail(f"{tid}: missing {field}")
    for field in ("dependencies", "expectedEvidence", "actualEvidence", "blockers"):
        if not isinstance(track.get(field), list):
            fail(f"{tid}: {field} must be a list")
    if track["status"] == "PASS" and not track["actualEvidence"]:
        fail(f"{tid}: PASS requires observed actualEvidence")
    if track["status"] in {"LOOP", "HALT", "WAITING"} and not track["blockers"]:
        fail(f"{tid}: {track['status']} requires a blocker/reason")

for tid, track in by_id.items():
    for dep in track["dependencies"]:
        if dep not in by_id:
            fail(f"{tid}: unknown dependency {dep}")
        if dep == tid:
            fail(f"{tid}: self dependency")

# Cycle detection.
visiting: set[str] = set()
visited: set[str] = set()

def visit(tid: str) -> None:
    if tid in visited:
        return
    if tid in visiting:
        fail(f"dependency cycle at {tid}")
    visiting.add(tid)
    for dep in by_id[tid]["dependencies"]:
        visit(dep)
    visiting.remove(tid)
    visited.add(tid)

for tid in by_id:
    visit(tid)

# A READY/LOOP track is selectable only when all dependencies have PASSed.
selectable = []
for track in tracks:
    if track["status"] not in {"READY", "LOOP"}:
        continue
    if all(by_id[d]["status"] == "PASS" for d in track["dependencies"]):
        selectable.append(track)

selectable.sort(key=lambda t: (t["priority"], t["targetDate"], t["id"]))

print(f"ROADMAP-PASS tracks={len(tracks)}")
if selectable:
    print("SELECTABLE")
    for t in selectable:
        print(f"  {t['priority']:02d} {t['id']} [{t['status']}] -> {t['nextSeed']}")
else:
    print("SELECTABLE none")
