# Đặc tả UI/UX hoàn chỉnh — Relearn Cards

Flow này sở hữu session type `relearn` độc lập cho Cards có terminal outcome chưa đạt. SRS policy quyết định next due state; source session không bị kéo dài bằng queue phát sinh mới.

## 1. Nguyên tắc đã chốt

- Relearn queue được tạo từ terminal outcomes đã commit của một session đã finalize, không từ transient wrong tap.
- Một Card xuất hiện tối đa một lần tại một queue position identity; retry không duplicate queue item.
- Relearn không xóa Attempts trước đó.
- User được biết còn bao nhiêu Cards cần relearn.
- Source session được finalize sau khi terminal outcomes commit; Relearn là session mới do user explicit start từ `Review missed`/relearn entry.
- Card trở thành due trong khi session đang chạy không được inject vào queue; nó thuộc một future `dueReview` session.
- Relearn không thay thế mastery retry round của Match, Guess, Recall hoặc Fill.

## 2. Entry conditions

| Condition | Queue |
| --- | --- |
| Finalized source session có terminal wrong | Eligible cho một Relearn session mới |
| Card becomes due during another active session | Không đổi active queue; future Due Review |
| Stage-level non-passing trong graded mode | Đưa vào mastery round kế của cùng mode; chưa enqueue Relearn |
| Hidden/deleted before queue turn | Skip với audit reason |

# 3. Master flow

```mermaid
flowchart TD
    A["Finalized session / Review missed"] --> B["Build stable Relearn snapshot"]
    B --> C["Start sessionType = relearn"]
    C --> D["Answer + commit terminal outcome"]
    D --> E{"Còn snapshot item?"}
    E -- "Có" --> D
    E -- "Không" --> F["Finalize Relearn session"]
    F --> G["Future due state follows SRS policy"]
```

# 4. Objective, archetype và composition

- Objective: củng cố một stable set Card đã missed trong một session độc lập.
- Archetype: Focused task/study flow.
- Primary CTA theo current stage interaction.

```text
Relearn
<remaining count> cards to revisit

<prompt + interaction>

                                               [ Next ]
```

- Due review không nằm trong surface này; entry của nó dùng `sessionType = dueReview`.

# 5. Queue and outcome rules

- Mastery retry round phải hoàn tất trước khi stage/mode tạo terminal outcome. Relearn chỉ xét terminal outcomes đã commit sau ranh giới đó.
- Một Card có thể có nhiều attempt qua các mastery round nhưng chỉ được enqueue Relearn theo terminal policy, không theo từng transient `wrong`/`almost`. Recall UI Forgot đã được map thành canonical `wrong`.
- Queue order ổn định theo session policy và được checkpoint.
- Relearn answer dùng cùng idempotent Attempt contract.
- Mỗi Card nhận một terminal outcome trong Relearn session; scheduler apply đúng một lần và tạo future due state. Không có current-session scheduling branch.
- Card resolved trong current Relearn snapshot sau khi mastery loop của mode plan hoàn tất; terminal sticky-wrong vẫn áp dụng cho SRS.
- Exit giữ remaining queue trong paused snapshot.

# 6. Lifecycle và errors

- Queue loading từ checkpoint; không recalculate tùy ý khi Resume.
- Save failure giữ answer/current queue position.
- Missing Card skip có reason, cập nhật remaining count, không substitute.
- Queue persistence failure: `Couldn’t save the relearn queue. Your answers are safe.` + Retry.
- Empty snapshot chuyển Finalize đúng một lần; không append Card mới phát sinh giữa session.

# 7. State matrix

- Relearn one/many remaining; resolved; future due scheduled.
- Saving/error/retry; resume mid-queue; missing Card.
- Long content/count, keyboard, large font, narrow device, light/dark.

# 8. Acceptance criteria

- Chỉ terminal committed outcome tạo queue item.
- Stage-level non-passing không được bỏ qua mastery round và không được chuyển thẳng thành Relearn item.
- Retry/resume không duplicate hoặc reorder queue.
- Relearn session còn snapshot item thì không finalize; source session không bị Relearn queue chặn finalize.
- Exit/Resume giữ current position và remaining items.
- Relearn/due-review canonical session states parity dưới 3% mỗi theme.
