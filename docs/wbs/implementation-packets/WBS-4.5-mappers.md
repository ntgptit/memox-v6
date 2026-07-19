# WBS 4.5 — Mapper/model layer implementation packet

| Field | Value |
| --- | --- |
| Status | **Done** (2026-07-19) |
| Owner/domain | Data + Domain / Persistence boundary |
| Depends on | `4.2` — Done; sits beside `4.4` DAOs |
| Decision gates | DG-06 (ADR-004), ADR-005 failure taxonomy |
| Acceptance | `AC-WBS-4.5-01` |
| Test | `TEST-WBS-4.5-01` |

## Canonical inputs

- WBS 4.5: explicit DB↔domain mapping, enum/version fallback and
  corruption errors; no domain dependence on Drift rows.
- ADR-005: every data error maps into the `AppFailure` taxonomy before
  presentation.
- `schema-v1.md`: preferences carry an explicit "invalid fallback" read
  contract.

## Scope

- `lib/domain/**` — the first domain model layer: plain immutable Dart
  classes with zero Drift imports, one aggregate per directory
  (language_pair, deck, flashcard + child content, learning_progress,
  study_session + snapshot/checkpoint/round-order/relearn/attempt,
  preferences, study_goal, study_streak). Typed enums
  (`SessionType`/`SessionScope`/`SessionState`) parse their stored
  strings and raise on unknowns. Timestamps are UTC `DateTime`s; flags
  are `bool`s.
- `lib/core/errors/app_failure.dart` — `DataCorruptionFailure` joins the
  taxonomy (entity/field/value context); repositories decide per call
  site whether corruption aborts the read or falls back.
- `lib/data/mappers/` — `primitive_mapper.dart` (UTC conversion, strict
  stored-bool, JSON string-list decode, try-decode) plus
  `{content,progress,session}_mapper.dart`: explicit field-by-field
  `toDomain()` extensions on every row class.
  `Preference.toDomainOrNull()` implements the invalid-payload fallback
  by returning null instead of corrupted entries.
- `test/data/mappers/mapper_test.dart` — pure Dart tests over
  constructed rows: timestamp/flag/soft-delete mapping, corrupted flag
  and unknown enum → typed failures with entity/field context, due
  semantics, preference fallback, checkpoint/round-order JSON decode
  and rejection.

## Acceptance and test procedure

`AC-WBS-4.5-01`: every schema-v1 aggregate has a Drift-free domain
model; each row class maps through an explicit mapper; unknown enum
values and invalid payloads surface as `DataCorruptionFailure` (or the
documented null fallback for preferences); no silent guessing.

`TEST-WBS-4.5-01`: `mapper_test.dart` in every gate. Run once through
`node tool/verify/run.mjs`.

## Failure and completion

- Success: register evidence recorded, `4.5` Done; `4.6` repository
  contracts can now compose DAOs + mappers + failure taxonomy.
