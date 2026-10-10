# Reflect call

Run `scripts/reflect-task.ps1` only after the check skill returned PASS. It reads each trail frame, always writes one earned constraint, and generates `nextSeed.intent` from that constraint. The meta level stays in `nextSeed.level`. `executed` is false.
