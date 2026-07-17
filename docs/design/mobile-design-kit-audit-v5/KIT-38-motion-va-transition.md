# KIT-38 — Motion và Transition

## Phạm vi

Audit tokens, navigation/state motion và reduced motion.

## Checklist

- [x] **KIT-38-01 — Mọi transition dùng duration/easing token; không có giá trị rời.**
  - **Cách kiểm:** VM-15 + VM-01 — inspect motion specs and token bindings.
  - **Evidence mong đợi:** Motion-token usage report.
  - **Severity mặc định nếu không đạt:** `P1`

- [ ] **KIT-38-02 — Push/pop, modal và pane transitions phản ánh đúng hierarchy.**
  - **Cách kiểm:** VM-15 — record navigation prototypes.
  - **Evidence mong đợi:** Transition clips.
  - **Severity mặc định nếu không đạt:** `P3`

- [x] **KIT-38-03 — Pressed, expand/collapse, selection và loading transitions không làm mất context.**
  - **Cách kiểm:** VM-15 + VM-09 — execute state changes.
  - **Evidence mong đợi:** Component-motion recordings.
  - **Severity mặc định nếu không đạt:** `P3`

- [ ] **KIT-38-04 — Swipe/drag motion theo finger và cancel trở về vị trí hợp lý.**
  - **Cách kiểm:** VM-15 — test completed/canceled gestures.
  - **Evidence mong đợi:** Gesture-motion clips.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-38-05 — Infinite/decorative motion không cạnh tranh vùng đọc hoặc gây distraction.**
  - **Cách kiểm:** VM-15 + VM-05 — inspect long-running examples.
  - **Evidence mong đợi:** Motion-risk audit.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-38-06 — Reduced-motion profile giữ đủ feedback và task usability.**
  - **Cách kiểm:** VM-15 + VM-10 — rerun critical flows with reduced motion.
  - **Evidence mong đợi:** So sánh chế độ chuyển động bình thường và giảm chuyển động.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-38-01 | `tokens/motion.css:8-23`; `components.css` (mọi `transition:` dùng `var(--memox-duration-*)`/`var(--memox-ease-*)`); `ui_kits/memox-app/index.html:56` (shimmer dùng `var(--memox-duration-pulse)`) | PASS | Không có ms/cubic-bezier rời; chỉ spinner `0.8s` được đánh dấu raw-ok. |
| KIT-38-02 | `tokens/motion.css` (scale instant/fast/base/slow theo surface); không có nav routing/clip | FAIL | Duration scale phản ánh hierarchy nhưng push/pop/modal/pane transition không được implement hay ghi lại (kit tĩnh). |
| KIT-38-03 | `components.css:246,330,565,816` (press = transform scale, selection = background, loading = opacity) | PASS | Transition tại chỗ, token-bound, giữ context; press scale 0.94–0.97 theo readme. |
| KIT-38-04 | Toàn kit không có gesture handler; `specs/*` không định nghĩa swipe/drag | FAIL | Không có swipe/drag motion; không thể chứng minh follow-finger/cancel-return. Hạ P2: mọi action đều button-driven nên không có blocker gesture (xem KIT-42-03). |
| KIT-38-05 | `ui_kits/memox-app/index.html:55-56` (shimmer opacity .5↔1, 1300ms); `components.css:1095` (spinner) | PASS | Chỉ loading indicator lặp, nhẹ, không cạnh tranh vùng đọc. |
| KIT-38-06 | `components.css:206-210,1098` (chỉ cappbar + spinner honor reduced-motion); `index.html:56` shimmer bỏ qua `prefers-reduced-motion`; `tokens/motion.css` không có reduced-motion token | FAIL | Reduced-motion profile không đủ: skeleton shimmer vẫn chạy, button/chip/fab/list transition không có override, không có global reset. |
| KIT-38-02 | SCOPE.md: transition clips out of scope (still-frame + parity contract) | ACCEPTED | Remediation — audit v5 fix loop. |
| KIT-38-04 | SCOPE.md: swipe/drag gesture motion out of scope (button-driven kit) | ACCEPTED | Remediation — audit v5 fix loop. |
| KIT-38-06 | components.css global prefers-reduced-motion reset incl. skeleton shimmer | FIXED | Remediation — audit v5 fix loop. |

## Kết luận nhóm

```text
Final status: PARTIAL
Open P0: 
Open P1: 
Open P2: 
Open P3: 
Reviewed by: Claude (automated kit audit + remediation)
Reviewed date: 2026-07-16
```
