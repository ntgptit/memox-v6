# WBS 2.10 — Foundation contract tests implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Design System + Flutter UI / Theme QA |
| Depends on | `2.2`–`2.9` — Done |
| Decision gates | DG-02, DG-05 |
| Acceptance | `AC-WBS-2.10-01` |
| Test | `TEST-WBS-2.10-01` |

## Position — the wave-2 gate

Token-value tests already run per family (CSS parity suites from 2.2–2.5
and 2.9). This item adds the cross-cutting contracts and locks the wave:

## Scope

Create:

- `test/core/theme/foundation_contract_test.dart` —
  1. **Token coverage pin**: byToken counts across every family sum to the
     207-token manifest (a silently dropped map entry now fails even if
     its parity suite were edited).
  2. **Theme completeness**: both ThemeData instances carry every
     foundation extension, are Material 3, and differ per theme.
  3. **No-raw-value source scans**: raw `Color(0x…)`/`Colors.*` and raw
     `Duration(...)` literals outside `lib/core/theme/**` fail inside
     `flutter test` — defense-in-depth double of the guard rules, so the
     contract also binds when contributors run tests directly.
- `test/core/theme/responsive/foundation_golden_test.dart` + 10 committed
  goldens — the themed app root at a representative width of every §5.3
  class (390/599/768/1024/1440) in light and dark, locking the
  token→theme→responsive composition. `Mx*` component goldens are owned by
  3.11/3.12; the 390×780 kit-parity (<3%) comparison applies when a
  reference shot exists for a real screen (5.x evidence).

## Acceptance and test procedure

`AC-WBS-2.10-01` is true only when:

1. The coverage pin equals the manifest count (207) via per-family sums.
2. Completeness and scan tests pass, and the scans would fail on an
   injected raw value (verified during development).
3. All 10 responsive goldens match.
4. Full canonical gate passes.

`TEST-WBS-2.10-01`: both new suites (14 tests) in every `flutter test`
gate; goldens regenerate only via reviewed `--update-goldens` changes. Run
once through `node tool/verify/run.mjs`.

## Failure and completion

- Success: wave 2 (`2.1`–`2.10`) closes. Record register evidence, mark
  `2.10` Done, then open wave 3 with the `3.1` packet (shared
  text/icon/tappable foundation).
