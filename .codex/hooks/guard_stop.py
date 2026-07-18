#!/usr/bin/env python3
"""Codex Stop hook: run the canonical MemoX quick verifier.

On violations (guard exit != 0) this exits with code 2, which blocks the agent
from ending its turn and feeds the guard output back so it can fix the issues.
When the guard passes it exits 0 and the turn ends normally.

"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
VERIFY = REPO_ROOT / "tool" / "verify" / "run.mjs"


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

    node = shutil.which("node")
    if node is None or not VERIFY.exists():
        print("verify: Node or tool/verify/run.mjs is missing", file=sys.stderr)
        return 2

    result = subprocess.run(
        [
            node,
            str(VERIFY),
            "--quick",
        ],
        capture_output=True,
        text=True,
    )

    if result.returncode == 0:
        return 0

    sys.stderr.write(
        "MemoX verification found violations that must be fixed before finishing:\n\n"
    )
    sys.stderr.write(result.stdout)
    sys.stderr.write(result.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
