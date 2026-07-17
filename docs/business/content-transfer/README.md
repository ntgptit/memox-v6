# Content Transfer business flows

Content Transfer sở hữu Import/Export jobs: source/file handling, parsing, mapping, duplicate plan, serialization và result file. Deck sở hữu target/scope eligibility; Flashcard sở hữu content validation.

## Invariants

- Import plan phải được preview trước commit khi source có mapping/duplicates/hierarchy.
- Import commit atomic theo confirmed plan.
- Export tạo consistent snapshot; không share partial file.
- Parser/serializer không bypass Deck/Flashcard invariants.
- Retry idempotent; không duplicate imported content hoặc export jobs.
- Source/config giữ qua recoverable failure.

## Flow catalog

| File | Flow sở hữu | Trạng thái |
| --- | --- | --- |
| [choose-import-source.md](./choose-import-source.md) | File/paste source, permission và read failure | Đã có |
| [map-import-fields.md](./map-import-fields.md) | Required field mapping và validation | Đã có |
| [preview-import.md](./preview-import.md) | Flat/hierarchy preview và invalid rows | Đã có |
| [resolve-import-duplicates.md](./resolve-import-duplicates.md) | Skip/merge/import-anyway plan | Đã có |
| [commit-import.md](./commit-import.md) | Progress, atomic write, retry và summary | Đã có |
| [configure-export.md](./configure-export.md) | Scope handoff, format và supported options | Đã có |
| [generate-export-file.md](./generate-export-file.md) | Snapshot, serialization, write và failure | Đã có |
| [share-export-file.md](./share-export-file.md) | Share/save result và share-only recovery | Đã có |

## Cross-object contracts

- Deck target/scope contract: `deck/import-deck.md`, `deck/export-deck.md`.
- Flat Card target eligibility: `deck/add-content-to-deck.md`.
- Flashcard validates term/meaning/translations before import commit.
- Backup không reuse content export nếu file thiếu full backup contract.

## Canonical state coverage

- Source/mapping/preview/duplicate/importing/error/done.
- Config/exporting/generation-error/done/share-error.
- Flat/hierarchy, empty/invalid/large source, long text, keyboard, narrow, light/dark.
