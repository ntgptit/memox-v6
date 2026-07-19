# WBS 4.10 — Architecture/data foundation gate (review packet)

| Field | Value |
| --- | --- |
| Status | **Done — gate PASSED** (2026-07-19) |
| Owner/domain | Architecture / QA |
| Depends on | `0.5`, `1.2–1.6`, `1.8–1.11`, `2.10`, `4.1–4.8` — all Done |
| Decision gates | This item **is** the gate: foundation must pass before feature UI begins |
| Acceptance | `AC-WBS-4.10-01` |
| Test | `TEST-WBS-4.10-01` |

## Gate checklist and evidence

| Gate requirement | Evidence |
| --- | --- |
| Accepted docs/traceability | `docs/database/schema-v1.md`, `migration-policy.md`, `riverpod-foundation.md` all Accepted; `work-item-register.md` carries per-item AC/TEST/evidence rows; every shipped item has an implementation packet (see `implementation-packets/README.md`) |
| Verifier | `node tool/verify/run.mjs` full run green at gate time: design checklist + token manifest, guard (246 rules, 0 errors, 0 `memox.*` warnings after 1.8), format (batched), analyze, **339 tests** |
| Bootstrap/error/router | Guarded error zone with redacted logging and safe build surface (1.4/1.5); route names/paths centralized with guard enforcement; `warmUpDiGraph` fail-fast ready for first-screen wiring (4.8) |
| Riverpod foundation | Accepted contract + generated keep-alive core providers + lifecycle/override/invalidation/retry contract tests (1.11) |
| l10n | en/vi ARB generation in the gate; localized test wrapper; corruption/conflict failures carry l10n copy (1.9, 4.5/4.6) |
| Test harness | Deterministic clock/ids, auto-disposed containers, reusable opener contract, restart harness, dense/dev fixtures (1.7/1.10) |
| Tier-1 Drift contracts | 17-table SQL-first schema + triggers + snapshot (4.2/4.3/4.7); 11 DAOs (4.4); Drift-free domain + mappers (4.5); 8 repository ports covering all seven atomic operations with idempotency/revision/rollback tests (4.6); DI graph (4.8); performance baseline pinning indexes and limits (4.9) |

## Recorded platform boundaries (carried forward, not gate blockers)

- On-device opener execution, web wasm assets, migration evidence,
  latency/memory budget measurement → Tier-1 platform smoke
  (5.7.4/16.1), using the reusable contract harness from 1.10.
- Multi-isolate contention evidence for the exclusivity triggers →
  same platform smoke (4.3 packet).
- Guard `ci` profile flip criteria recorded in `profiles.yaml` (1.8).

## Acceptance and test procedure

`AC-WBS-4.10-01`: every dependency row is Done with packet + register
evidence; the full canonical gate passes; the remaining platform
boundaries are explicitly recorded with owners. **All satisfied
2026-07-19.**

`TEST-WBS-4.10-01`: the full `node tool/verify/run.mjs` run itself.

## Failure and completion

- Gate PASSED. Feature UI may begin: next is `3.12` (minimal Mx gate)
  per the sequencing note, then the wave-5 critical path
  (`5.1` onward) in dependency order.
