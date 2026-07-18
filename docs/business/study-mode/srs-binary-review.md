# Đặc tả nghiệp vụ — SRS Binary Review

SRS Binary Review là pure Study Mode strategy dùng cho `dueReview` và fallback
của `relearn`. Đây không phải mode người dùng chọn trong Practice picker.

## 1. Interaction contract

| Input | Rule |
| --- | --- |
| Prompt | Term và meaning snapshot của đúng Card đều hiển thị |
| Actions | `Remembered` hoặc `Relearn` |
| `Remembered` | Canonical `correct` |
| `Relearn` | Canonical `wrong` và Card vào failed set của current mastery round |
| Missing/duplicate action | Reject hoặc trả prior result theo attempt identity |

Không có timer, hint hoặc inference từ thời gian. Localized label và màu UI
không phải domain input.

## 2. Session semantics

- `dueReview` luôn freeze plan `due-review-binary-v1` và dùng strategy này.
- `relearn` freeze `relearn-binary-v1` khi stable snapshot không có ít nhất năm
  distinct meaning choices cho Guess.
- Action `Relearn` tạo sticky wrong trong **current session**. Card phải pass ở
  mastery retry round trước khi session hoàn tất, nhưng terminal grade vẫn wrong.
- Một `relearn` session mới schedule từ persisted current box. `Remembered` có
  thể promote một box dù một session trước đã demote Card; đây là behavior đã
  chấp nhận, không phải undo trong cùng transaction.
- Strategy chỉ trả evidence; Study Session persist Attempt/checkpoint và Learning
  Progress áp dụng `leitner-8-box-v1` đúng một lần.

## 3. Error/idempotency

- Same attempt identity + same payload trả prior canonical evidence.
- Same identity + different action là conflict.
- Stale checkpoint hoặc Card không còn hợp lệ không tạo Attempt/grade.
- Unsupported plan/mode configuration fail closed trước khi render prompt.

## 4. Acceptance criteria

- Hai action map deterministic tới `correct|wrong` và có non-color affordance.
- Due Review không phụ thuộc distractor pool.
- Relearn dùng binary đúng khi Guess precondition không đạt.
- Wrong retry không mất lapse trong current session.
- Factory resolve đúng một `SrsBinaryReviewStudyModeStrategy` cho
  `StudyModeType.srsBinaryReview`.
