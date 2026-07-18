# SRS Policy v1 — Leitner 8 Box

Tài liệu này là source of truth cho thuật toán lập lịch SRS của MemoX v6. Learning Progress sở hữu policy; Study Mode tạo evidence, Study Session tổng hợp terminal grade, còn data layer chỉ persist kết quả và bảo đảm transaction/idempotency.

## 1. Phạm vi và định danh policy

| Trường | Giá trị |
| --- | --- |
| Policy id | `leitner-8-box-v1` |
| Số box SRS | 8, đánh số `1..8` |
| Trạng thái trước SRS | `box = 0` (`new`, chưa activate) |
| Grade engine nhận | `correct` hoặc `wrong` |
| Clock | Inject từ ngoài; engine không gọi `DateTime.now()` |
| Persistence time | UTC |

Policy này không dùng ease factor, SM-2 hoặc FSRS. Không tạo lịch riêng cho chiều term→meaning và meaning→term trong v1; một Card có một current SRS state.

## 2. Mô hình box và interval

`Box 0` không phải một trong tám box SRS. Nó biểu diễn Card mới chưa hoàn thành learning flow và chưa có `dueAt`.

| Box | Trạng thái | Interval sau khi vào box | `dueAt` |
| ---: | --- | ---: | --- |
| 0 | New / chưa activate | Không áp dụng | `null` |
| 1 | SRS mới activate / cần củng cố dày | 1 ngày | `now + 1 day` |
| 2 | Đang củng cố | 3 ngày | `now + 3 days` |
| 3 | Đang củng cố | 7 ngày | `now + 7 days` |
| 4 | Ổn định ban đầu | 14 ngày | `now + 14 days` |
| 5 | Ổn định | 30 ngày | `now + 30 days` |
| 6 | Ghi nhớ tốt | 60 ngày | `now + 60 days` |
| 7 | Ghi nhớ rất tốt | 120 ngày | `now + 120 days` |
| 8 | Mastered | Không xếp lịch tiếp | `null` |

Interval `1 · 3 · 7 · 14 · 30 · 60 · 120` và tám box phải giữ đồng bộ với state `settings/study-srs` của MemoX Design System v4. Trong v1, đây là policy cố định; Settings chỉ hiển thị, không cho đổi số box hoặc interval. Thay đổi policy sau này cần policy id mới, migration và decision table riêng.

## 3. Kích hoạt SRS cho Card mới

Card mới được khởi tạo với:

```text
box = 0
dueAt = null
srsActivatedAt = null
policyId = leitner-8-box-v1
```

Card chỉ chuyển `0 → 1` khi toàn bộ New Learning Flow đã hoàn thành:

1. Review hoàn tất.
2. Match hoàn tất mastery round cuối với failed set rỗng.
3. Guess hoàn tất mastery round cuối với failed set rỗng.
4. Recall hoàn tất mastery round cuối với failed set rỗng.
5. Fill hoàn tất mastery round cuối với failed set rỗng.
6. Không còn Attempt/checkpoint write đang pending.
7. Study Session phát terminal activation outcome đúng một lần.

Activation result:

```text
box = 1
dueAt = activationTimeUtc + 1 day
srsActivatedAt = activationTimeUtc
lastReviewedAt = activationTimeUtc
```

Thoát/pause trước khi hoàn tất đủ năm mode không activate SRS. Card vẫn ở Box 0; các Attempt đã commit vẫn giữ trong history và checkpoint để Resume.

## 4. Chuẩn hóa terminal grade

SRS engine chỉ nhận grade binary `correct` hoặc `wrong`. Study Mode không gọi scheduler trực tiếp. Study Session tổng hợp evidence của Card trong một SRS review session thành đúng một terminal grade:

| Evidence trong session hiện tại | Terminal grade |
| --- | --- |
| Mọi graded interaction đều pass ngay ở lần xuất hiện đầu của round đầu; không có `wrong`, `almost` hoặc timeout | `correct` |
| Có ít nhất một committed `wrong`, `almost` hoặc Recall timeout ở bất kỳ mastery round nào | `wrong` |
| Card sai rồi đạt ở retry round | Vẫn là `wrong`; retry chứng minh mastery nhưng không xóa lapse |
| Review-only `reviewed` | Không tạo SRS grade |
| Attempt chưa commit, duplicate retry hoặc invalid interaction | Không tham gia terminal grade |
| Missing/skipped Card theo snapshot recovery | Không giả thành `correct`; phải có audit reason |

Quy tắc “wrong sticky trong một session” giải quyết mâu thuẫn giữa mastery loop và Leitner: user vẫn phải học lại đến khi đạt để hoàn tất session, nhưng Card đã từng sai vẫn bị hạ box đúng một lần khi terminal outcome được commit.

## 5. Chuyển box

Với Card đã activate (`box 1..8`):

```text
correct → nextBox = min(currentBox + 1, 8)
wrong   → nextBox = max(currentBox - 1, 1)
```

| Current box | Grade | Next box | Next due |
| ---: | --- | ---: | --- |
| 1 | `correct` | 2 | +3 ngày |
| 1 | `wrong` | 1 | +1 ngày |
| 4 | `correct` | 5 | +30 ngày |
| 4 | `wrong` | 3 | +7 ngày |
| 7 | `correct` | 8 | `null` — mastered |
| 8 | `correct` | 8 | `null` — vẫn mastered |
| 8 | `wrong` | 7 | +120 ngày |

Không có Box 9 và Card đã activate không quay về Box 0 do trả lời sai. Box 0 chỉ quay lại qua explicit reset-progress flow.

## 6. Tính lịch và eligibility

Sau khi xác định `nextBox`:

```text
lastReviewedAt = nowUtc
dueAt = null                              nếu nextBox == 8
dueAt = nowUtc + interval(nextBox) days   nếu nextBox thuộc 1..7
```

`day` trong công thức là duration 24 giờ. Instant được lưu UTC; presentation format theo locale/timezone. Card thuộc Due queue khi `box` thuộc 1..7, `dueAt != null`, `dueAt <= nowUtc`, Card không hidden/deleted và thuộc requested Deck scope.

Box 0 đi vào New queue, không vào Due queue. Box 8 đi vào learned/mastered projection, không vào Due/New/Relearn queue.

## 7. Atomicity và idempotency

Mỗi terminal scheduling operation có stable `terminalOutcomeId`. Trong một data-layer transaction:

1. Kiểm tra `terminalOutcomeId` đã apply chưa.
2. Lock/serialize current Progress của Card.
3. Validate current box, policy id và session terminal grade.
4. Tính next state bằng pure domain policy.
5. Persist terminal outcome, Progress mới và checkpoint/finalization boundary.
6. Commit.

Retry cùng `terminalOutcomeId` trả lại cùng result, không chuyển box lần hai. Hai terminal outcomes khác nhau cho cùng Card không được last-write-wins im lặng; stale writer phải nhận typed conflict.

## 8. Counters và history

| Field | Rule |
| --- | --- |
| `repetitions` | Tăng 1 cho mỗi terminal SRS grade đã commit |
| `lapses` | Tăng 1 khi terminal grade là `wrong` |
| `lastReviewedAt` | Set bằng injected `nowUtc` khi terminal grade được apply |
| `policyId` | Lưu `leitner-8-box-v1` cho quyết định này |
| `boxBefore` / `boxAfter` | Lưu trong history để audit/rebuild Statistics |
| Intermediate Attempt | Giữ trong history nhưng không tự đổi box/due |

## 9. Queue priority

Trong một requested scope:

1. Relearn items thuộc current active Session, theo checkpoint order.
2. Due Cards Box 1..7, `dueAt` tăng dần; tie-break bằng stable Card id.
3. New Cards Box 0, theo policy new-card limit và stable ordering.

Một Card chỉ xuất hiện một lần trong effective queue. Box 8 không được đưa lại vào queue nếu chưa có explicit reset hoặc future policy migration.

## 10. Reset và lifecycle

- Reset Card/Deck progress đưa Card về Box 0, `dueAt = null` và xóa current scheduling metrics theo reset contract.
- Hide loại Card khỏi mọi queue nhưng giữ box/due hiện tại.
- Unhide re-evaluate eligibility từ persisted due instant; không tự đổi box.
- Delete Card xóa current Progress theo atomic lifecycle owner và retention policy.
- Move hoặc edit Card giữ nguyên box/due vì Card identity không đổi.

## 11. Decision table tối thiểu

| ID | Given | When | Then |
| --- | --- | --- | --- |
| SRS8-001 | Card Box 0 hoàn tất đủ 5 mode | Activate | Box 1, due +1 ngày, policy v1 |
| SRS8-002 | Card Box 0 pause/exit trước khi đủ 5 mode | Save checkpoint | Vẫn Box 0, due null |
| SRS8-003 | Card Box 1 terminal correct | Apply | Box 2, due +3 ngày |
| SRS8-004 | Card Box 1 terminal wrong | Apply | Box 1, due +1 ngày |
| SRS8-005 | Card Box 4 terminal correct | Apply | Box 5, due +30 ngày |
| SRS8-006 | Card Box 4 terminal wrong | Apply | Box 3, due +7 ngày |
| SRS8-007 | Card Box 7 terminal correct | Apply | Box 8, due null |
| SRS8-008 | Card Box 8 terminal correct | Apply | Giữ Box 8, due null |
| SRS8-009 | Card Box 8 terminal wrong | Apply | Box 7, due +120 ngày |
| SRS8-010 | Card có wrong rồi correct ở retry round | Finalize Card | Terminal grade wrong, hạ đúng 1 box |
| SRS8-011 | Cùng terminalOutcomeId được retry | Apply | Trả same result, không đổi box lần hai |
| SRS8-012 | Hai writer khác outcome trên cùng version | Apply stale writer | Typed conflict, không overwrite |
| SRS8-013 | Box 7 dueAt bằng nowUtc | Build Due queue | Card được coi là due |
| SRS8-014 | Box 8 | Build queues | Không thuộc Due/New/Relearn |
| SRS8-015 | Hidden Card Box 1..7 đã due | Build queues | Bị loại nhưng state không đổi |
| SRS8-016 | Reset progress | Commit reset | Box 0, due null |

Mỗi row bắt buộc có ít nhất một test và test phải dẫn lại ID.

## 12. Acceptance criteria

- Chỉ có tám box SRS `1..8`; Box 0 là pre-SRS state.
- Card mới chỉ vào Box 1 sau khi hoàn thành đủ năm mode.
- Correct tăng đúng một box với trần 8; wrong giảm đúng một box với sàn 1.
- Interval cố định theo Box 1..7 là `1, 3, 7, 14, 30, 60, 120` ngày.
- Box 8 mastered có `dueAt = null` và không nằm trong study queues.
- Wrong trong bất kỳ mastery round nào vẫn tạo terminal wrong dù retry sau đó đạt.
- Intermediate Attempt không tự schedule; terminal outcome schedule đúng một lần.
- Engine thuần, nhận clock/policy/input từ ngoài và không import Flutter/Drift/Riverpod.
- Attempt, box transition, due time và checkpoint/finalization luôn nhất quán qua transaction.
- Queue, Dashboard, Statistics, Export và Reset cùng đọc một SRS state contract.

