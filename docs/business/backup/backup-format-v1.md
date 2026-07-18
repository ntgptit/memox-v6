# Backup format v1 — `memox-backup-v1`

Đây là canonical logical container contract; physical archive/encryption implementation không được đổi semantics hoặc field ids.

## Manifest

| Field | Required | Rule |
| --- | ---: | --- |
| `formatId` | Yes | Exact `memox-backup-v1` |
| `schemaVersion` | Yes | Positive integer |
| `createdAtUtc` | Yes | UTC ISO-8601 instant |
| `sourceAppVersion` | Yes | Informational; compatibility không chỉ dựa field này |
| `snapshotId` | Yes | Stable UUID for one logical backup |
| `contentHashAlgorithm` | Yes | `sha256` in v1 |
| `entries[]` | Yes | Sorted canonical path, byte length, SHA-256 |
| `objectCounts` | Yes | Counts by aggregate; verified after decode |
| `capabilities[]` | Yes | Included optional groups such as audio/account-free settings |
| `encryption` | Yes | `none` or supported versioned descriptor; secrets never stored plaintext |

Required entries: `manifest.json`, `language-pairs.jsonl`, `decks.jsonl`, `flashcards.jsonl`, `progress.jsonl`, `attempts.jsonl`, `sessions.jsonl`, `preferences.json`, `goals.jsonl`, `reminders.jsonl`. Optional binary assets live under `assets/<sha256>` and are content-addressed.

Account credentials, access/refresh tokens, OS permission grants, transient caches, search/statistics projections and active cryptographic secrets are never exported. Projections rebuild from source records.

## Integrity and size

- Serialize a consistent database snapshot; write temporary artifact, close it, verify every entry hash/count, then publish atomically.
- Inspect rejects duplicate paths, path traversal, negative/overflow lengths, unsupported compression/encryption, hash mismatch and manifest/count mismatch.
- Parsers stream with explicit configured limits; limits are environment configuration surfaced before deep parse, never hidden magic constants in domain policy.
- Filename is sanitized; original local paths are never embedded.

## Compatibility and migration

`schemaVersion` migration is ordered and copy-on-write. Newer unsupported fails closed. Migrated copy must pass current hashes, schemas and aggregate invariants before Restore is enabled. Original artifact remains unchanged.

## Acceptance criteria

- Round-trip fixtures cover empty, representative, large/streamed and all optional capability groups.
- Tampered/truncated/path-traversal archives fail before local mutation.
- Same logical snapshot yields stable record identities and object counts.
- Restore Merge/Replace behavior follows [DATA-MERGE-v1](../../decision-tables/backup-sync-integrity.md).
