# Content transfer formats v1

## Supported formats

| Format id | Import | Export | Hierarchy | Required encoding/shape |
| --- | ---: | ---: | ---: | --- |
| `memox-csv-v1` | Yes | Yes | No | UTF-8, RFC 4180 quoting, header row |
| `memox-json-v1` | Yes | Yes | Yes | UTF-8 JSON object with versioned schema |

CSV required mapped fields are `term` and `meaning`; optional fields are `translations`, `tags`, `audioRef` and `hidden`. Multi-value fields use JSON-array text, not an unescaped delimiter. Column order is irrelevant after mapping. Invalid UTF-8, duplicate headers without index disambiguation and rows exceeding configured limits are reported before commit.

JSON root fields: `formatId`, `formatVersion`, `languagePair`, `decks[]`, `cards[]`, `exportedAtUtc`, `contentHash`. Deck records use stable export-local ids and `parentId`; Card records reference exactly one Leaf Deck. Import validates acyclic hierarchy, exclusive Empty/Leaf/Parent content and all Flashcard fields before preview.

Neither format includes Learning Progress, Attempts, Sessions, Preferences, Account tokens or device permissions. Full recovery uses [Backup format v1](../backup/backup-format-v1.md).

## Duplicate and idempotency

Import source fingerprint + confirmed plan id + row identity form `importOperationId`. Retry returns prior row result. Stable ids from another installation are treated as external ids and never overwrite local records without an explicit duplicate decision.

## Acceptance criteria

- Golden fixtures cover quoting/newlines/Unicode, invalid rows, duplicate normalized content, hierarchy cycles and mixed Deck attempts.
- Export→import round trip preserves supported content fields and hierarchy.
- Preview row counts and committed counts reconcile by status.
- Parser uses streaming/configured resource limits and never publishes partial content.
