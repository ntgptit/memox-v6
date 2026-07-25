#!/usr/bin/env python3
"""Claude Code Stop hook: run the canonical MemoX quick verifier.

On violations (guard exit != 0) this exits with code 2, which blocks the agent
from ending its turn and feeds the guard output back so it can fix the issues.
When the guard passes it exits 0 and the turn ends normally.

Golden and kit-parity tests are pinned to a Windows host (WBS §6.5), so on
any other platform they compare a local rasterisation against a Windows
baseline and fail on sub-1% drift no matter what the change was. CI already
encodes that split: `ci_scope.mjs` keeps those tests out of the Ubuntu gate
and only `Full Canonical (Windows)` runs them. This hook mirrors it, so a
non-Windows host verifies everything it can actually verify instead of
blocking on a difference it cannot fix. On Windows the run is unchanged.

"""

from __future__ import annotations

import json
import platform
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


def _non_visual_tests(node: str) -> list[str]:
    """Every test path except the ones owned by the Windows visual gate."""
    script = (
        "import('./tool/verify/ci_scope.mjs').then("
        "(m) => process.stdout.write(m.listNonVisualTests().join('\\n')))"
    )
    result = subprocess.run(
        [node, "--input-type=module", "-e", script],
        cwd=str(REPO_ROOT),
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return []
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def main() -> int:
    payload = _read_hook_input()

    # Avoid an infinite stop loop: if we already blocked once this turn, let it end.
    if payload.get("stop_hook_active"):
        return 0

    node = shutil.which("node")
    if node is None or not VERIFY.exists():
        print("verify: Node or tool/verify/run.mjs is missing", file=sys.stderr)
        return 2

    command = [node, str(VERIFY), "--quick"]
    if platform.system() != "Windows":
        # Narrow to the non-visual suite; an empty list means the helper
        # failed, and falling back to the full run is the safe direction.
        for path in _non_visual_tests(node):
            command += ["--test", path]

    result = subprocess.run(command, capture_output=True, text=True)

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
