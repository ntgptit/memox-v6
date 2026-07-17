# Study Mode business flows

Study Mode là tập strategy biến Card prompt và user interaction thành canonical stage evidence cho Study Session. Object này không persist Session/Progress trực tiếp.

## Invariants

- Mode chỉ chạy khi scope đáp ứng minimum eligibility của mode.
- Cùng interaction state tạo deterministic canonical evidence.
- UI feedback không được tự update SRS; Session ghi Attempt, Progress schedule terminal outcome.
- Stage completion phải rõ và idempotent qua Retry/Resume.
- Mode không tự thay đổi Card content hoặc Deck scope.
- Accessibility không được phụ thuộc color, drag hoặc audio duy nhất.
- Review không có outcome đúng/sai và chỉ chạy một lượt browse.
- Match, Guess, Recall và Fill chạy một hoặc nhiều mastery round. Round đầu nhận toàn bộ Card của stage; round kế chỉ nhận tập Card không đạt của round vừa hoàn tất.
- Tập Card không đạt phải được khử trùng theo Card identity. Card đã đạt không xuất hiện lại trong round kế tiếp.
- Một graded mode chỉ complete và chuyển mode khi round vừa hoàn tất có `nextRoundFailedCardIds` rỗng. Không giới hạn số mastery round.
- Implementation của cả năm mode bắt buộc tuân theo [Factory Pattern + DI architecture](./factory-di-architecture.md): canonical enum, common interface, abstract template base, năm concrete modes và factory được inject instances.

## Mastery-round contract

| Mode | Outcome đạt | Outcome không đạt và phải học lại |
| --- | --- | --- |
| Review | `reviewed` | Không áp dụng |
| Match | Pair đúng ngay trong round | `wrong` hoặc `almost` |
| Guess | `correct` | `wrong` |
| Recall | `correct` từ UI Remembered | `wrong` từ UI Forgot hoặc hết countdown 20 giây |
| Fill | `correct` | `wrong` |

- `currentRoundCardIds` là immutable trong lúc round đang chạy; `nextRoundFailedCardIds` được tích lũy từ committed evidence của chính round đó.
- Mỗi Card tạo tối đa một mastery classification trong một round. Riêng Match có thể có nhiều selection event nhưng classification là non-passing nếu Card từng có `wrong`/`almost` trong round.
- Round kế giữ đúng membership của các Card không đạt sau khi lọc từ `currentRoundCardIds`, rồi tạo một deterministic permutation mới cho round đó.
- Khi hết `currentRoundCardIds`, nếu `nextRoundFailedCardIds` không rỗng thì tăng `roundIndex`, dùng chính tập đó làm round mới và reset tập failed kế tiếp.
- Persistence Retry chỉ gửi lại cùng attempt; mastery round tạo attempt identity mới. Hai khái niệm này không được dùng thay nhau.
- Exit/Resume phải giữ `mode`, `roundIndex`, `currentRoundCardIds`, vị trí hiện tại và `nextRoundFailedCardIds`.
- Missing/invalid Card được xử lý theo snapshot skip policy có audit reason; không được ghi giả là correct để thoát mastery loop.
- Mọi Guess question bắt buộc có đúng năm lựa chọn gồm một correct và bốn distractor hợp lệ lấy từ stable session snapshot; không được giảm option count ở retry round.
- Recall dùng Remembered/Forgot chỉ ở presentation layer. Mapper bắt buộc trả `correct/wrong`; timeout trước reveal map thành `wrong(reason = timeout)` và Card phải vào retry round.

## Order-randomization contract

- Review, Match, Guess, Recall và Fill không dùng lại nguyên thứ tự Card của mode trước. Mỗi mode round tạo order từ `MODE_ROUND_ORDER_SEED = hash(sessionId, modeId, roundIndex, shuffleVersion)`.
- Round 1 của mode mới shuffle độc lập từ toàn bộ Card stage. Nếu có từ hai Card trở lên, sequence không được giống hệt sequence của mode ngay trước; collision phải được resolve bằng deterministic reshuffle/rotation.
- Mastery retry round cũng shuffle độc lập từ failed set. Nếu failed set có từ hai Card trở lên, không giữ nguyên sequence tương ứng của round trước.
- Một Card là trường hợp duy nhất không thể đổi order; UI không giả lập shuffle.
- Order đã tạo phải được persist trong checkpoint. Re-render, persistence Retry, Exit/Resume không được shuffle lại.
- Cùng session/checkpoint/shuffle version luôn dựng cùng order; session mới hoặc mode/round mới tạo seed mới.
- Shuffle chỉ đổi presentation order, không đổi Card identity, mastery membership, evidence hoặc đáp án.

## Flow catalog

| File | Flow sở hữu | Trạng thái |
| --- | --- | --- |
| [review-cards.md](./review-cards.md) | Quick-review term + meaning trước graded stages | Đã có |
| [match-terms-and-meanings.md](./match-terms-and-meanings.md) | Pair selection, correct/wrong/almost và completion | Đã có |
| [guess-card-meaning.md](./guess-card-meaning.md) | Choice generation, answer và feedback | Đã có |
| [recall-and-self-grade.md](./recall-and-self-grade.md) | Reveal, UI Remembered/Forgot → canonical correct/wrong | Đã có |
| [fill-card-answer.md](./fill-card-answer.md) | Text input, hint, comparison và feedback | Đã có |
| [map-mode-outcome.md](./map-mode-outcome.md) | Chuẩn hóa mode-specific evidence cho Session | Đã có |

## Implementation architecture

- [factory-di-architecture.md](./factory-di-architecture.md) là contract bắt buộc cho lần refactor/implementation code tiếp theo.
- Architecture được mô tả trung lập công nghệ; agent phải ánh xạ sang construct phù hợp của stack hiện tại nhưng không được bỏ các vai trò enum/interface/abstract base/concrete modes/factory/DI.
- Tài liệu được chốt không đồng nghĩa source hiện tại đã tuân thủ; chỉ đánh dấu implemented sau khi code và contract tests đạt Definition of Done trong tài liệu này.

## Cross-object contracts

- Nhận Card content snapshot, stage position và effective Preferences từ Study Session.
- Trả canonical evidence cho `study-session/answer-study-stage.md`.
- Learning Progress không đọc UI state trực tiếp.
- Card edit/audio actions mở Flashcard contract và không mutate current snapshot im lặng.

## Canonical state coverage

- Review browsing/editing/audio/loading/error/end.
- Match playing/selected/correct/wrong/almost/round-complete/retry-round/complete.
- Guess waiting-five-options/correct/wrong/invalid-distractor-pool/round-complete/retry-round/long-text/complete.
- Recall UI countdown/manual-revealed/timeout-revealed/Forgot-explicit/Forgot-timeout/Remembered; canonical correct/wrong; round-complete/retry-round/complete.
- Fill waiting/typing/hint/correct/wrong/round-complete/retry-round/complete.
- Keyboard, large font, narrow device, light/dark cho từng mode.
- Deterministic shuffled order theo mode/round; Resume giữ order; collision với mode/round trước được resolve.
