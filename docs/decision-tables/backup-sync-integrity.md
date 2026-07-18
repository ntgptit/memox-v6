# DATA-MERGE-v1 — Backup restore and sync integrity

| ID | Context | Condition | Result |
| --- | --- | --- | --- |
| DATA-MERGE-001 | Restore Replace | Inspected fingerprint/version unchanged | Atomically replace full included dataset; rebuild projections |
| DATA-MERGE-002 | Restore Replace | Fingerprint/local version changed | Block and re-inspect/reconfirm |
| DATA-MERGE-003 | Restore Merge | Object exists only one side | Insert unchanged after invariant validation |
| DATA-MERGE-004 | Restore Merge | Same stable id and same content version/hash | Dedupe; do not duplicate |
| DATA-MERGE-005 | Restore Merge | Same stable id, divergent content | Create explicit conflict; do not auto overwrite |
| DATA-MERGE-006 | Restore Merge | Deck parent change would create cycle/mixed content | Block plan before commit |
| DATA-MERGE-007 | Restore Merge | Attempt/terminal outcome same identity | Dedupe; never reapply schedule |
| DATA-MERGE-008 | Restore Merge | Progress versions diverge | No field-wise merge; explicit local/backup choice, revalidate Card/policy |
| DATA-MERGE-009 | Sync | Same event/version retry | Return prior acknowledgement; watermark unchanged/advanced once |
| DATA-MERGE-010 | Sync | Different edits share base | Three-way field merge only for Preferences/metadata fields declared mergeable; otherwise conflict |
| DATA-MERGE-011 | Any | Unknown commit outcome | Read transaction/event identity before retry |
| DATA-MERGE-012 | Any | Validation/integrity failure | Roll back whole operation; persist recovery state, not partial success |

Mergeable-field registry v1: Preferences scalar fields and non-structural Deck description may use three-way merge when only one side changed each field. Deck parent, Deck content type, Card term/meaning, Progress, Attempts, Session checkpoints and SRS history are not field-mergeable.
