# Account and Sync business flows

Account sở hữu authentication state và sync coordination. MemoX local data vẫn usable khi signed out/offline; Account không thay thế local objects làm source of truth.

## Invariants

- Sign-in không được xóa/ghi đè local data im lặng.
- Sign-out không xóa local data trừ khi user chọn một destructive flow riêng.
- Sync status rõ: signed-out, idle, syncing, success, offline, error hoặc conflict.
- Một conflict cần explicit resolution policy; không mặc định cloud thắng.
- Retry sync idempotent; không duplicate Deck/Card/Attempt.
- Account deletion khác Sign-out và cần đặc tả riêng nếu product hỗ trợ.

## Flow catalog

| File | Flow sở hữu | Trạng thái |
| --- | --- | --- |
| [sign-in.md](./sign-in.md) | Authentication, return và local-data review | Đã có |
| [sign-out.md](./sign-out.md) | End session và local-data preservation | Đã có |
| [sync-local-data.md](./sync-local-data.md) | Upload/download coordination, progress và retry | Đã có |
| [resolve-sync-conflict.md](./resolve-sync-conflict.md) | Compare, choose/merge và atomic apply | Đã có |
| [recover-account-session.md](./recover-account-session.md) | Expired credentials, re-auth và offline continuation | Đã có |
| [delete-account.md](./delete-account.md) | Identity/cloud impact và local-data choice nếu supported | Đã có — Conditional |

## Cross-object contracts

- Sync transports versioned Deck, Card, Progress, Preferences và Goal records.
- Mỗi object vẫn validate invariants khi remote changes được apply.
- Backup là explicit snapshot/restore; Sync là ongoing reconciliation.
- UI phải phân biệt auth error, network error và data conflict.

## Canonical state coverage

- Signed-out/in; signing-in; syncing; success; offline; error; conflict.
- Local-only data before sign-in; large dataset; session expired.
- Long account labels, large font, narrow device, light/dark.
