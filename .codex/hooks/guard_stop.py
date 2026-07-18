#!/usr/bin/env python3
"""Claude Code Stop hook: run the code guard on agent-produced changes.

On violations (guard exit != 0) this exits with code 2, which blocks the agent
from ending its turn and feeds the guard output back so it can fix the issues.
When the guard passes it exits 0 and the turn ends normally.

Profile: local -> fails on ERRORS only (warnings are reported, not fatal).
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
GUARD = REPO_ROOT / "tools" / "code-verification-guard" / "guard" / "run.py"
RULESET = "memox"
PROFILE = "local"


def _read_hook_input() -> dict:
    """Read the Stop hook payload from stdin, tolerating an empty stream."""
    try:
        raw = sys.stdin.read()
    except Exception:
        return {}
    if not raw.strip():
        return {}
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {}


def main() -> int:
    payload = _read_hook_input()

    # Avoid an infinite stop loop: if we already blocked once this turn, let it end.
    if payload.get("stop_hook_active"):
        return 0

    if not GUARD.exists():
        # Do not block when the guard isn't set up; just leave a hint.
        print(
            "guard: submodule not initialized "
            "(git submodule update --init --recursive)",
            file=sys.stderr,
        )
        return 0

    result = subprocess.run(
        [
            sys.executable,
            str(GUARD),
            "check",
            "--project",
            str(REPO_ROOT),
            "--ruleset",
            RULESET,
            "--profile",
            PROFILE,
        ],
        capture_output=True,
        text=True,
    )

    if result.returncode == 0:
        return 0

    sys.stderr.write(
        "Code guard found violations that must be fixed before finishing:\n\n"
    )
    sys.stderr.write(result.stdout)
    sys.stderr.write(result.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
