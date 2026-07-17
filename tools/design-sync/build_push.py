#!/usr/bin/env python3
"""Build a DesignSync push plan: diff the local kit against the remote project and
emit ready-to-send write_files batches.

This packages the DETERMINISTIC half of a `/design-sync` push. The actual upload
(DesignSync finalize_plan + write_files) must run through Claude's MCP tool — it
requires the claude.ai login and per-plan approval, so a plain script cannot do it.
This tool prepares the exact inputs Claude then feeds to DesignSync.

Workflow
--------
  1. In Claude:  DesignSync list_files  -> save the JSON result to a file, e.g. remote.json
  2. Shell:      python tools/design-sync/build_push.py --remote remote.json
  3. In Claude:  DesignSync finalize_plan   (use localDir + writes from out/plan.json, deletes=[])
                 DesignSync write_files      (one call per out/batch_N.json, passed as `files`)

Defaults (project id, kit dir, exclusions, batch size) come from config.json next to
this script; override any with CLI flags.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from collections import Counter
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent


def load_config() -> dict:
    cfg_path = SCRIPT_DIR / "config.json"
    if cfg_path.exists():
        return json.loads(cfg_path.read_text(encoding="utf-8"))
    return {}


def is_excluded(rel: str, dirs, parts, basenames) -> bool:
    if any(rel == d or rel.startswith(d + "/") for d in dirs):
        return True
    if any(part in ("/" + rel) for part in parts):
        return True
    if os.path.basename(rel) in basenames:
        return True
    return False


def main() -> int:
    cfg = load_config()

    ap = argparse.ArgumentParser(description="Build a DesignSync push plan (diff + batches).")
    ap.add_argument("--remote", required=True, help="Path to a DesignSync list_files JSON result")
    ap.add_argument("--kit", default=cfg.get("kitDir"), help="Local kit dir (repo-relative or absolute)")
    ap.add_argument("--out", default=str(SCRIPT_DIR / "out"), help="Output dir for plan.json + batches")
    ap.add_argument("--batch", type=int, default=cfg.get("batchSize", 200), help="Max files per write_files batch")
    args = ap.parse_args()

    if not args.kit:
        return _fail("no kit dir (set kitDir in config.json or pass --kit)")

    kit = Path(args.kit)
    if not kit.is_absolute():
        kit = (REPO_ROOT / kit)
    kit = kit.resolve()
    if not kit.is_dir():
        return _fail(f"kit dir not found: {kit}")

    remote_path = Path(args.remote)
    if not remote_path.is_file():
        return _fail(f"remote list not found: {remote_path} (run DesignSync list_files and save it)")
    remote_data = json.loads(remote_path.read_text(encoding="utf-8"))
    remote_files = {p for p in remote_data.get("paths", []) if os.path.splitext(p)[1]}

    dirs = tuple(cfg.get("excludeDirs", ["uploads"]))
    parts = tuple(cfg.get("excludePathParts", ["/shots/", "/_sheets/", "/evidence/"]))
    basenames = tuple(cfg.get("excludeBasenames", [".thumbnail", ".source-hash"]))

    local = {p.relative_to(kit).as_posix() for p in kit.rglob("*") if p.is_file()}

    only_local = sorted(local - remote_files)
    only_remote = sorted(remote_files - local)
    push = sorted(r for r in local if not is_excluded(r, dirs, parts, basenames))

    # finalize_plan writes: top-level globs covering the push set (authorized superset).
    tops = sorted({(r.split("/", 1)[0] if "/" in r else r) for r in push})
    writes = [f"{t}/**" if (kit / t).is_dir() else t for t in tops]

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    entries = [{"path": p, "localPath": p} for p in push]
    size = max(1, args.batch)
    batches = [entries[i:i + size] for i in range(0, len(entries), size)]
    for i, b in enumerate(batches, 1):
        (out / f"batch_{i}.json").write_text(json.dumps(b, ensure_ascii=False), encoding="utf-8")

    only_local_excluded = [r for r in only_local if is_excluded(r, dirs, parts, basenames)]
    only_local_would_push = [r for r in only_local if not is_excluded(r, dirs, parts, basenames)]

    plan = {
        "projectId": cfg.get("projectId"),
        "projectName": cfg.get("projectName"),
        "localDir": str(kit),
        "finalize_plan": {"writes": writes, "deletes": []},
        "counts": {
            "local": len(local),
            "remoteFiles": len(remote_files),
            "push": len(push),
            "batches": len(batches),
            "onlyLocal": len(only_local),
            "onlyRemotePreserved": len(only_remote),
        },
        "onlyRemotePreserved": only_remote,
        "onlyLocalExcludedFromPush": only_local_excluded,
        "onlyLocalNewToPush": only_local_would_push,
        "batchFiles": [f"batch_{i}.json" for i in range(1, len(batches) + 1)],
    }
    (out / "plan.json").write_text(json.dumps(plan, indent=2, ensure_ascii=False), encoding="utf-8")

    # ---- human summary ----
    print(f"DesignSync push plan  ->  {cfg.get('projectName')}  ({cfg.get('projectId')})")
    print(f"  localDir : {kit}")
    print(f"  local {len(local)} files | remote {len(remote_files)} files")
    print(f"  PUSH     : {len(push)} files in {len(batches)} batch(es) of {size}")
    print(f"  by top   : {dict(Counter(r.split('/')[0] for r in push))}")
    print(f"  PRESERVE : {len(only_remote)} remote-only file(s) (deletes=[], never removed)")
    for r in only_remote:
        print(f"     keep  {r}")
    if only_local_would_push:
        print(f"  NEW local files being pushed (not yet on remote): {len(only_local_would_push)}")
        for r in only_local_would_push:
            print(f"     add   {r}")
    if only_local_excluded:
        print(f"  local-only but excluded by rules: {len(only_local_excluded)} (e.g. {only_local_excluded[:3]})")
    print()
    print("Next — hand these to DesignSync (in Claude):")
    print(f"  finalize_plan: projectId={cfg.get('projectId')}")
    print(f"                 localDir={kit}")
    print(f"                 writes={json.dumps(writes)}")
    print(f"                 deletes=[]")
    print(f"  write_files  : one call per batch, pass out/batch_N.json as `files`")
    print(f"  wrote: {out / 'plan.json'} + {len(batches)} batch file(s)")
    return 0


def _fail(msg: str) -> int:
    print(f"build_push: {msg}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
