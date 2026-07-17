# Study Mode implementation architecture — Factory Pattern + DI

Tài liệu này quy định cấu trúc triển khai bắt buộc cho năm Study Mode: Review, Match, Guess, Recall và Fill.

Đây là architecture contract trung lập công nghệ. Ví dụ tư duy xuất phát từ Java/Spring, nhưng implementation agent phải chuyển sang construct tương đương của stack hiện tại mà vẫn giữ nguyên vai trò, dependency direction và extension points dưới đây.

## 1. Mục tiêu

- Gom luồng xử lý chung của năm mode vào một nơi.
- Chọn mode bằng enum và factory, không rải `switch/if` theo mode trong orchestrator/UI.
- Cho phép thay đổi logic riêng của một mode bằng override hook phù hợp, không copy toàn bộ luồng chính.
- Mọi dependency được truyền từ ngoài qua DI; mode không tự tìm repository/service hoặc tạo dependency ẩn.
- Thêm mode mới bằng một concrete implementation và đăng ký DI, không sửa luồng chính đang ổn định.

## 2. Cấu trúc bắt buộc

```text
StudyModeType enum
        │
        ▼
StudyMode interface
  - getMode(): StudyModeType
  - process(context, input): result
        │ implements
        ▼
AbstractStudyMode
  - process(): luồng chính dùng chung
  - common concrete methods
  - abstract/overridable hooks
        │ extends
        ├── ReviewStudyMode
        ├── MatchStudyMode
        ├── GuessStudyMode
        ├── RecallStudyMode
        └── FillStudyMode

DI container / composition root
        │ inject all mode instances
        ▼
StudyModeFactory
  - get(mode): StudyMode
```

Tên class/interface có thể thay đổi theo convention của công nghệ, nhưng năm vai trò `enum → interface → abstract base → concrete modes → factory/DI` không được loại bỏ hoặc gộp vào UI.

## 3. Enum nhận diện mode

Phải có một enum/type canonical duy nhất chứa đúng năm giá trị:

```text
REVIEW
MATCH
GUESS
RECALL
FILL
```

- Giá trị persist/wire hiện có như `review`, `match`, `guess`, `recall`, `fill` phải map 1:1 với enum.
- Không tạo enum thứ hai cho cùng khái niệm ở UI hoặc data layer.
- Factory và `getMode()` phải dùng enum canonical này, không dùng raw string.

## 4. Interface chung

Interface tối thiểu gồm:

```text
interface StudyMode {
  getMode(): StudyModeType
  process(context, input): Result
}
```

### `getMode()`

- Trả đúng enum mà instance sở hữu.
- Ổn định trong toàn bộ lifetime của instance.
- Factory dùng giá trị này để đăng ký và lookup.

### `process()`

- Là entry point duy nhất của orchestrator vào logic mode.
- Trả result typed/canonical; không trả trực tiếp widget, localized copy hoặc DB row.
- Hành vi idempotent theo attempt/checkpoint contract.
- Concrete mode không được tạo một entry point song song để bypass common flow.

## 5. Abstract base — Template Method

`AbstractStudyMode` implements interface và sở hữu luồng chính. Đây là nơi triển khai các bước dùng chung bằng concrete methods và gọi abstract/overridable hooks cho phần khác biệt.

Pseudo-flow bắt buộc của `process()`:

```text
process(context, input):
  1. validate session, mode, checkpoint và event identity
  2. load current Card/round state
  3. prepare deterministic mode/round order
  4. validate interaction bằng mode hook
  5. evaluate bằng mode hook
  6. map về canonical evidence/outcome
  7. persist Attempt idempotently
  8. update nextRoundFailedCardIds/checkpoint
  9. quyết định next Card, retry round, next mode hoặc finalize
  10. trả result typed cho caller
```

Abstract base có thể cung cấp concrete methods dùng chung như:

- validate session/checkpoint/attempt identity
- build attempt metadata
- persist Attempt và recover save failure
- khử trùng failed Card set
- tạo mastery retry round
- deterministic shuffle theo mode/round
- advance checkpoint
- resolve next mode/finalization
- map common error thành typed result

Abstract/overridable hooks tối thiểu:

```text
getMode()
validateModeInput(context, input)
evaluateModeInteraction(context, input)
buildModeMetadata(context, evaluation)
```

Base class có thể cung cấp default implementation cho hook không bắt buộc. Concrete mode chỉ override hook cần thay đổi. Không copy toàn bộ `process()` vào từng mode.

Nếu ngôn ngữ hỗ trợ `final`, implementation có thể khóa `process()` và chỉ mở protected hooks. Nếu không hỗ trợ, contract test/code review phải bảo đảm concrete mode không bypass template flow.

## 6. Năm concrete mode

Mỗi concrete class extends abstract base và chỉ sở hữu policy riêng:

| Concrete mode | Logic riêng cần override |
| --- | --- |
| Review | Browse term + meaning; không có correct/wrong; không tạo mastery retry round |
| Match | Pair selection, wrong/almost classification và pair resolution |
| Guess | Đúng năm options, một correct + bốn distractors, option validation |
| Recall | Countdown 20 giây; UI Remembered/Forgot map thành canonical correct/wrong; timeout map wrong |
| Fill | Normalize/compare typed answer, hint metadata và validation |

Các invariant chung như idempotency, checkpoint, retry round, shuffle, persistence và mode transition vẫn phải đi qua abstract base.

## 7. Factory

Factory nhận toàn bộ mode instances qua constructor/DI và tạo registry theo enum:

```text
class StudyModeFactory {
  constructor(modes: Collection<StudyMode>)
  get(mode: StudyModeType): StudyMode
}
```

Factory phải:

- đăng ký đúng một instance cho mỗi enum
- fail fast nếu thiếu một trong năm mode
- fail fast nếu hai instances trả cùng enum
- fail closed với enum không hỗ trợ
- trả instance đã được DI hoàn chỉnh; không tự `new` repository/service bên trong `get()`
- không chứa business logic của từng mode

Orchestrator chỉ được gọi theo dạng:

```text
handler = studyModeFactory.get(checkpoint.mode)
result = handler.process(context, input)
```

Không duy trì một `switch/if` thứ hai để chạy logic theo mode sau khi đã lookup factory.

## 8. Dependency Injection

- Common dependencies được inject vào abstract base qua constructor hoặc mechanism tương đương.
- Dependency riêng của mode được inject vào concrete mode tương ứng.
- Factory được inject collection/map của interface instances.
- Session orchestrator phụ thuộc `StudyModeFactory` hoặc factory interface, không phụ thuộc năm concrete classes.
- UI chỉ phát semantic event và render state; UI không resolve repository, timer store, shuffle service hoặc persistence service.
- Không dùng global mutable singleton, service locator hoặc import trực tiếp concrete dependency để giả lập DI.
- Không bắt buộc thêm DI library. Manual constructor injection/composition root hợp lệ nếu bảo đảm các boundary trên.

Ví dụ ánh xạ theo công nghệ:

- Java/Spring: interface + abstract class + `@Component` implementations + inject `List<StudyMode>` vào factory.
- TypeScript/React/Expo: interface + abstract class + constructor injection + registry được tạo tại composition root/provider.
- Dart/Flutter: abstract class + concrete implementations + provider/container inject collection/factory.

Agent phải dùng idiom tự nhiên của stack hiện tại; không sao chép annotation hoặc lifecycle của framework khác một cách máy móc.

## 9. Dependency direction

```text
UI / route
    → session orchestrator
        → StudyModeFactory
            → StudyMode interface
                → AbstractStudyMode
                    → domain ports/use cases

Concrete modes → AbstractStudyMode
Data adapters → domain ports
Composition root → concrete modes + factory
```

- Domain không import UI, route hoặc DB adapter.
- Factory lookup không nằm trong screen/hook rendering.
- Concrete mode không gọi concrete mode khác.
- Mode transition do common flow quyết định từ canonical result/checkpoint.

## 10. Error và extension rules

- Missing/duplicate registration là startup/configuration error, không fallback sang mode khác.
- Unsupported mode fail closed; không tự dùng Review làm default.
- Override không được bỏ qua persistence, idempotency, failed-set hoặc checkpoint rules.
- Thay đổi common flow phải sửa abstract base và common contract tests.
- Thay đổi chỉ một mode phải ưu tiên override hook của mode đó.
- Thêm mode mới yêu cầu enum value, concrete class, DI registration và contract tests; caller/factory algorithm không đổi.

## 11. Test contract

- Contract test chạy cho cả năm implementations qua interface.
- Factory test xác nhận đủ năm enum, lookup đúng instance, missing/duplicate fail fast.
- Abstract-base test xác nhận thứ tự pipeline và không bypass persistence/checkpoint.
- Mỗi concrete mode có targeted tests cho hook riêng.
- DI test dùng fake/mock ports, không cần UI hoặc DB thật để test domain flow.
- Regression test xác nhận orchestrator không chứa business `switch/if` theo năm mode.
- Existing mode requirements vẫn phải được test: mastery rounds, deterministic shuffle, Guess five options, Recall timeout và correct/wrong mapping.

## 12. Definition of Done cho lần triển khai code sau

- Có một canonical mode enum.
- Có interface với `getMode()` và `process()`.
- Có abstract base chứa template flow dùng chung.
- Có đúng năm concrete mode implementations extends base.
- Factory nhận instances qua DI và fail fast khi registry sai.
- Orchestrator resolve mode qua factory và gọi `process()`.
- Không còn duplicate common orchestration trong năm mode controllers/hooks.
- Domain/UI/data dependency direction đúng ADR kiến trúc của repo.
- Contract/unit/integration tests liên quan pass.

Tài liệu này chỉ chốt architecture requirement. Nó không khẳng định source code hiện tại đã được refactor theo pattern này.
