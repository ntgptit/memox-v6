# design-sync utility

Packages the **diff + push-plan** half of syncing the local kit
(`docs/design/MemoX Design System_v4/`) up to its **claude.ai/design** project.

## Why a helper (and its boundary)

The actual upload — `DesignSync finalize_plan` + `write_files` — runs through
Claude's MCP tool. It needs the claude.ai login and a per-plan approval, so a plain
script **cannot** perform the push. What a script *can* do deterministically is the
diff and the batch-file construction. This tool does exactly that and prints the
inputs Claude then hands to DesignSync.

## Usage

```bash
# 1. In Claude: run DesignSync list_files for the project, save the JSON result:
#      -> remote.json   (the {"paths":[...]} object)

# 2. Build the plan + batches:
python tools/design-sync/build_push.py --remote remote.json

# 3. In Claude, using tools/design-sync/out/plan.json:
#      DesignSync finalize_plan  (projectId, localDir, writes, deletes=[])
#      DesignSync write_files     (one call per out/batch_N.json, passed as `files`)
```

Flags (all optional; defaults from `config.json`):
`--remote <file>` (required) · `--kit <dir>` · `--out <dir>` · `--batch <n>`.

## What it outputs (`out/`, gitignored)

- `plan.json` — `projectId`, `localDir`, the `finalize_plan` `writes` globs +
  `deletes: []`, counts, and the **preserved** remote-only files.
- `batch_1.json`, `batch_2.json`, … — `write_files` `files` arrays (≤ `batchSize` each).

## Sync policy (encoded in `config.json`)

- **Direction:** local → remote (push). Local is treated as source of truth.
- **Never wholesale-replace:** `deletes` is always empty, so files that exist only
  on remote are **preserved**, never removed. The script lists them so you can
  decide separately (e.g. pull them down) if needed.
- **Excluded from push** (redundant or scratch, not design source):
  - `excludeDirs`: `uploads/` (pasted scratch; canonical font lives in `fonts/`)
  - `excludePathParts`: `/shots/`, `/_sheets/`, `/evidence/` (QA render artifacts
    the remote already holds identically)
  - `excludeBasenames`: `.thumbnail`, `.source-hash` (local tooling artifacts)

Adjust these in `config.json` to change what syncs.

## Note

`out/` is regenerated each run and is gitignored — only the script + config + this
README are versioned. `DesignSync` is a reviewed, on-demand sync, not an unattended
job: re-run this whenever the local kit changes, then approve the plan in Claude.
