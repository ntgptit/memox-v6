# Backup business flows

Backup sở hữu explicit snapshot, file compatibility và restore transaction. Nó khác Export content (dùng để chia sẻ học liệu) và khác Sync (ongoing reconciliation).

## Invariants

- Backup snapshot có version và integrity metadata.
- Successful backup đại diện một consistent point-in-time dataset.
- Restore validate compatibility/integrity trước khi mutate local data.
- Restore failure rollback toàn bộ; không để database half-restored.
- User phải biết restore sẽ merge hay replace trước confirm.
- Backup file có thể chứa dữ liệu nhạy cảm; share/storage copy phải cảnh báo phù hợp.

## Flow catalog

| File | Flow sở hữu | Trạng thái |
| --- | --- | --- |
| [create-local-backup.md](./create-local-backup.md) | Snapshot, write file, progress và done | Đã có |
| [inspect-backup.md](./inspect-backup.md) | Version, date, object counts và integrity preview | Đã có |
| [restore-local-backup.md](./restore-local-backup.md) | Merge/replace decision, confirm và transaction | Đã có |
| [handle-backup-compatibility.md](./handle-backup-compatibility.md) | Older/newer/corrupt file decisions | Đã có |
| [recover-backup-failure.md](./recover-backup-failure.md) | Retry, rollback verification và support copy | Đã có |
| [manage-cloud-backup.md](./manage-cloud-backup.md) | Cloud snapshot lifecycle khi provider được duyệt | Đã có — Conditional |

## Cross-object contracts

- Snapshot bao gồm versioned records của objects đã được backup policy chốt.
- Restore gọi validation của từng object trước commit.
- Content Transfer export không được gắn nhãn Backup nếu thiếu progress/settings/history.
- Account provider chỉ transport/store backup; Backup sở hữu compatibility/restore.

## Canonical state coverage

- Config/creating/error/done; inspect valid/old/new/corrupt.
- Restore review/confirm/restoring/failure/rollback/success.
- Empty/large dataset, low storage, cancelled file picker, light/dark presentation.
