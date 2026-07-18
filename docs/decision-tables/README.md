# MemoX decision-table catalog

Các bảng trong thư mục này là executable business contracts: mỗi row có ID ổn định và phải được tham chiếu bởi ít nhất một automated test. Thay đổi semantics của row cần version mới hoặc migration note; không đổi nghĩa âm thầm dưới cùng ID.

| Contract | Owner | Applies to |
| --- | --- | --- |
| [ST-SESSION-TYPE-v1](./study-session-types.md) | Study Session | Session type, mode plan, mutations |
| [ST-CONTENT-CHANGE-v1](./study-session-content-changes.md) | Study Session | Edit/move/hide/delete trong active session |
| [SM-MATCH-v1](./match-outcomes.md) | Study Mode | Match correct/wrong/almost |
| [SM-FILL-v1](./fill-answer-normalization.md) | Study Mode | Fill normalization/comparison |
| [SRS8-v1](./srs-8-box-v1.md) | Learning Progress | Activation, transition, due, reset, idempotency |
| [DATA-MERGE-v1](./backup-sync-integrity.md) | Backup + Account | Restore merge và sync conflict integrity |

## Test contract

- Tên hoặc metadata test phải chứa exact row ID.
- Mỗi row có happy-path test; row concurrency/retry có integration test với deterministic clock/storage fake.
- Coverage checker fail khi row ID không có test hoặc test dẫn ID không tồn tại.
- `Given/When/Then` dùng domain values; không dùng widget class hoặc database implementation detail.
