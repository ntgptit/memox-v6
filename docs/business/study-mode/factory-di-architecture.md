# Study Mode Factory và DI architecture

- Status: **Normative — mandatory**
- Owner: Study Mode / Architecture

Tài liệu này bắt buộc dùng Factory Pattern để phân giải Study Mode. Factory chỉ
chọn pure-domain strategy; Study Session vẫn sở hữu Attempt, checkpoint,
mastery round và scheduling transaction.

## 1. Mode type và concrete strategies

`StudyModeType` là closed enum gồm đúng sáu giá trị:

| Type | Concrete strategy | Dùng bởi |
| --- | --- | --- |
| `review` | `ReviewStudyModeStrategy` | New Learning, Practice |
| `match` | `MatchStudyModeStrategy` | New Learning, Practice |
| `guess` | `GuessStudyModeStrategy` | New Learning, Practice, Relearn đủ pool |
| `recall` | `RecallStudyModeStrategy` | New Learning, Practice |
| `fill` | `FillStudyModeStrategy` | New Learning, Practice |
| `srsBinaryReview` | `SrsBinaryReviewStudyModeStrategy` | Due Review, Relearn fallback |

Mỗi strategy nhận typed interaction + immutable prompt snapshot, validate rồi
trả canonical evidence. Strategy không được import Flutter, Riverpod, Drift,
repository hoặc clock toàn cục.

## 2. Mandatory Factory contract

`StudyModeFactory.create(StudyModeType type)` phải:

1. Exhaustively map mỗi enum value tới đúng một concrete strategy.
2. Trả cùng contract `StudyModeStrategy`; caller không `switch` lại theo mode.
3. Fail fast với typed configuration error nếu thiếu, trùng hoặc không hỗ trợ
   registration; không fallback sang mode khác.
4. Không chọn session plan, không đọc database và không persist.

Một registry có thể dùng bên trong factory để test override, nhưng factory vẫn
là public construction boundary bắt buộc. Không service locator và không
factory lồng cho từng interaction.

## 3. Shared template contract

`StudyModeStrategyBase` là template thuần và chỉ chuẩn hóa ba bước:

```text
validate(input) → evaluate(validInput) → mapCanonicalEvidence(result)
```

Concrete strategy sở hữu rule khác biệt của mode. Template không ghi Attempt,
không advance checkpoint, không dựng retry round và không schedule SRS. Nếu Dart
sealed interface cung cấp cùng invariant rõ hơn, base có thể là sealed abstract
class, nhưng ba bước và sáu concrete strategies vẫn bắt buộc.

## 4. Riverpod composition

- `lib/app/di/app_providers.dart` khai báo generated `@Riverpod(keepAlive: true)`
  provider tạo một `StudyModeFactory` với đủ sáu strategies.
- Application use case nhận factory qua constructor/provider injection.
- Test override provider bằng factory chứa fakes; domain không gọi `ref.read`.
- Study Session resolve plan đã freeze, gọi factory cho current mode, rồi sở hữu
  transaction ghi Attempt/checkpoint/terminal outcome.

Intended domain layout:

```text
lib/domain/study_modes/
  study_mode_type.dart
  study_mode_strategy.dart
  study_mode_factory.dart
  strategies/
    review_study_mode_strategy.dart
    match_study_mode_strategy.dart
    guess_study_mode_strategy.dart
    recall_study_mode_strategy.dart
    fill_study_mode_strategy.dart
    srs_binary_review_study_mode_strategy.dart
```

## 5. Factory acceptance/test contract

- Contract test enumerate toàn bộ `StudyModeType`, assert đúng concrete type và
  không null/duplicate registration.
- Missing/duplicate registration fixture phải fail fast trước khi start session.
- Mỗi strategy chạy toàn bộ decision-table rows mà không cần Widget/Drift.
- Application test chứng minh Attempt được lưu trước checkpoint và factory/
  strategy không gọi persistence.
- Provider override test chứng minh composition thay thế được trong test.
- Adding một enum value làm exhaustive factory/test fail cho tới khi có strategy.

Canonical behavior nằm tại [Study Mode README](./README.md),
[Map Mode Outcome](./map-mode-outcome.md), [SRS Binary Review](./srs-binary-review.md)
và [ST-SESSION-TYPE-v1](../../decision-tables/study-session-types.md).
