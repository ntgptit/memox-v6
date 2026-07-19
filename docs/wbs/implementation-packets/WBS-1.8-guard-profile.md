# WBS 1.8 — Raise guard profile implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Tooling / Quality gates |
| Depends on | `1.1–1.7` — Done |
| Decision gates | — |
| Acceptance | `AC-WBS-1.8-01` |
| Test | `TEST-WBS-1.8-01` |

## Canonical inputs

- WBS 1.8: active source paths have no stale-target warnings; CI moves
  from `local` toward `ci` after approved cleanup.
- Guard warning inventory before cleanup: 98 (75 rule-without-targets,
  14 missing-target-path, 2 shared-widget docs, 1 oversized test file).

## Scope (cleanup applied)

- **Zero `memox.*` warnings remain.** `MxGap`/`MxDivider` Public API
  doc sections now use the `- name:` bullet contract; the drift_dev
  generated schema helpers are excluded from
  `memox.testing.max_test_file_lines` (generated, never hand-split).
- **Every stale literal path with a real counterpart fixed**:
  `app_shell.dart` → `app.dart`; `mx_search_controller_hooks.dart` →
  `mx_search_hooks.dart`; the SharedPreferences DI exclusion now globs
  `lib/app/di/*_providers.dart`; removed the obsolete
  `deck_repository_impl.dart` max-lines exception,
  `flashcard_export_writer.dart` naming exception and the
  `router/redirect.dart` allow-entries (re-add with the file if a
  dedicated redirect module ever lands); future feature viewmodels in
  scopes resolve by glob instead of per-file paths.
- Remaining warnings are exclusively `guard.config.*` coverage
  meta-diagnostics for rules whose targets are future wave-5 feature
  paths — they shrink to zero as features land.

## CI profile decision

The `ci` profile (warnings-as-errors) cannot be adopted yet: the guard
hard-codes config meta-diagnostics as warnings and `disabled_rules`
does not scope them, so `ci` would fail on future-path coverage notes
alone. The flip criteria are recorded in `profiles.yaml`: adopt `ci`
when rule-without-targets reaches zero (wave 5) or the guard learns to
scope config meta-diagnostics. Until then the verifier stays on
`local`, which now runs with **zero actionable warnings**.

## Acceptance and test procedure

`AC-WBS-1.8-01`: no `memox.*` warnings; no missing-target path that has
a real counterpart; the ci flip criteria are written next to the
profile.

`TEST-WBS-1.8-01`: the guard step of `node tool/verify/run.mjs` (the
ruleset regression pytest suite runs inside it).

## Failure and completion

- Success: register evidence recorded, `1.8` Done; next candidates:
  `4.9` review item and the `4.10` foundation gate.
