# Validation and normalization catalog

- Status: **Canonical cross-object index**
- Owner: Product / Domain
- Updated: 2026-07-18

This catalog centralizes rules that were previously scattered across object flows. It does not
replace the owning object document: when a row links to an owner, that owner defines the invariant
and this page provides a stable validation reference.

## Shared rules

| ID | Input/boundary | Normalize before comparison | Reject condition | Error contract |
| --- | --- | --- | --- | --- |
| VAL-001 | User-entered required text | Unicode NFC, trim outer whitespace | Result is empty | Field error; draft remains intact |
| VAL-002 | Optional user text | Unicode NFC, trim outer whitespace | Never solely because it is empty | Store `null`/absence, not a semantic empty value |
| VAL-003 | Stable object ID | No UI normalization; ID provider owns creation | Missing, malformed for the configured provider, or already used | Typed validation/conflict failure |
| VAL-004 | User-visible uniqueness | Apply the owning object's documented normalized comparison key | Key already exists in the documented scope | Conflict identifies scope and recovery action |
| VAL-005 | Date/time persistence | Convert instants to UTC; retain timezone only when the business rule needs local recurrence | Invalid/unresolvable instant | Typed time validation failure |
| VAL-006 | File/import boundary | Validate type, schema/version, integrity and resource budget before mutation | Any preflight check fails | No partial mutation; actionable import/restore error |
| VAL-007 | Command retry | Reuse the same idempotency key for the same logical command | Same key carries a different payload | Typed idempotency conflict |

Normalization used for duplicate detection must not silently rewrite the user's display value.
Locale-sensitive comparison is forbidden unless the owning object explicitly requires it.

## Object index

| Object/capability | Required validation | Canonical owner |
| --- | --- | --- |
| Language Pair | Source and target are present, supported, distinct; normalized pair is unique | [`language-pair/README.md`](./language-pair/README.md) |
| Deck | Name satisfies VAL-001; sibling identity is unique; target preserves Empty/Leaf/Parent exclusivity and acyclicity | [`deck/README.md`](./deck/README.md) |
| Flashcard | Required term/meaning satisfy VAL-001; target is eligible; duplicate content enters review instead of silent overwrite | [`flashcard/README.md`](./flashcard/README.md) |
| Card translation | Text and language satisfy VAL-001; ordering is stable; normalized duplicates are not added twice | [`flashcard/manage-card-translations.md`](./flashcard/manage-card-translations.md) |
| Card tag | Label satisfies TAG-001..TAG-006 | [`flashcard/manage-card-tags.md`](./flashcard/manage-card-tags.md) |
| Study Session | Session type, eligible snapshot, active-session policy and idempotency key are valid before creation | [`study-session/README.md`](./study-session/README.md) |
| Mode answer | Mode-specific normalization and outcome table are deterministic | [`study-mode/README.md`](./study-mode/README.md) |
| Learning Progress/SRS | Policy ID, terminal outcome, UTC clock and transition row are valid; scheduling occurs once | [`learning-progress/srs-8-box-policy.md`](./learning-progress/srs-8-box-policy.md) |
| Study Goal | Enabled target is a positive whole number; disabled goal has no active target | [`study-goal/README.md`](./study-goal/README.md) |
| Reminder | Local schedule/timezone and platform permission/capability are valid before enable | [`reminder/README.md`](./reminder/README.md) |
| Search | Query normalization never mutates stored content; empty query follows the owning search contract | [`search/README.md`](./search/README.md) |
| Content Transfer | Format/version/column mapping and resource budget pass preflight before commit | [`content-transfer/formats-v1.md`](./content-transfer/formats-v1.md) |
| Backup/Restore | Manifest, checksum, compatibility, available storage and merge/replace decision pass before transaction | [`backup/backup-format-v1.md`](./backup/backup-format-v1.md) |
| Account/Sync | Credentials, provider gate, record versions and merge decision validate without making cloud authoritative | [`account/cloud-service-gate.md`](./account/cloud-service-gate.md) |

## Acceptance and test contract

- Every rejecting row has one boundary test and one presentation mapping test.
- Unicode fixtures include composed/decomposed Vietnamese, mixed-script content and outer/inner
  whitespace.
- Repository tests prove failed validation performs zero durable writes.
- Retry tests prove the same idempotency key is safe and a changed payload is rejected.
- A feature-specific rule may strengthen this catalog, but may not weaken it without a recorded
  Product/Domain decision.
