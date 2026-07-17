# KIT-19 — Interaction Specification

## Phạm vi

Audit hành vi input/gesture/back ở cấp component.

## Checklist

- [x] **KIT-19-01 — Tap action, hit area và pressed feedback được mô tả cho mọi control.**
  - **Cách kiểm:** VM-09 + VM-10 — walkthrough representative controls.
  - **Evidence mong đợi:** Interaction notes and target measurements.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-19-02 — Long press hoặc swipe chỉ dùng khi có đường thay thế discoverable.**
  - **Cách kiểm:** VM-09 + VM-12 — inspect gesture patterns and alternatives.
  - **Evidence mong đợi:** Gesture-to-alternative matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [ ] **KIT-19-03 — Drag/reorder có handle, picked state, drop target và cancel behavior.**
  - **Cách kiểm:** VM-09 — execute successful and canceled drag.
  - **Evidence mong đợi:** Prototype recording and state screenshots.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-19-04 — Back, close, outside-tap và swipe-dismiss không mâu thuẫn.**
  - **Cách kiểm:** VM-09 — test each dismiss path on overlays/editors.
  - **Evidence mong đợi:** Dismiss behavior matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-19-05 — Keyboard/pointer profile có focus activation bằng Enter/Space và visible focus.**
  - **Cách kiểm:** VM-09 + VM-10 — hardware keyboard walkthrough.
  - **Evidence mong đợi:** Focus-order recording and control checklist.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-19-06 — Haptic/sound chỉ là bổ sung, không phải tín hiệu bắt buộc duy nhất.**
  - **Cách kiểm:** VM-12 + VM-10 — review feedback spec with sensory alternatives.
  - **Evidence mong đợi:** Sensory feedback matrix.
  - **Severity mặc định nếu không đạt:** `P3`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-19-01 | `components.css:246-252` (card press scale 0.985 + hover lift), `:334-339` (.btn:active scale 0.97), `:468-475` (.icon-btn hover/active 0.9), `:565-575` (.fab active 0.94), `:979-1013` (hit-area ::after overlays lift small controls to 48px), `tokens/spacing.css:29` `--memox-touch-min:48px`; prompt.md interaction notes | PASS | Every control has documented tap/hover/press feedback + measured ≥48px hit area. |
| KIT-19-02 | Grep: no `long-press` anywhere; only gesture is `_features/review-mode/ReviewMode.jsx:63` "Swipe to continue", with the study flow primary CTA **Next** button (`specs/study-session.md` Primary CTA Next) as the discoverable alternative | PASS | Sole swipe has an equivalent button path; no long-press used. |
| KIT-19-03 | Grep across `components/` + `_features/`: no `drag`/`reorder`/`sortable`/`handle`/`drop target` pattern; ordering is handled by SortSheet (`library` `sort-sheet` state) instead | FAIL | No drag/reorder pattern with handle/picked/drop/cancel is specified. P2 (down from P1): reorder not in product scope, sort is the provided alternative. |
| KIT-19-04 | `ui_kits/memox-app/kit-helpers.jsx:107` Scrim backdrop (outside-tap area), `:116-119` Sheet grabber (swipe affordance), `components/surfaces/MxContextualAppBar.jsx:62-64` modal/nested close+back, `_shared/ConfirmDialog.jsx` explicit dialog actions | PASS | Each overlay type has one coherent, non-conflicting dismiss affordance set (sheet=grabber+scrim, dialog=buttons, modal=appbar close). |
| KIT-19-05 | Enter/Space OK: native `<button>` for btn/icon-btn/fab/bottom-nav/segmented; ARIA buttons add keydown (`MxCard.jsx:14`, `MxSectionHeader.jsx:7`). Visible focus rings on `.btn`/`.icon-btn`/`.fab` (`components.css:337-339,474-476,573-575`) BUT text inputs suppress it: `.field` `:928` `outline:none` with no `:focus` ring, `.cappbar__search-input:196`, `.search-dock__input:612` | FAIL | Keyboard activation is fine, but text inputs show no visible focus indicator (only caret); `search-dock--focused` is prop-driven, not `:focus`-driven. P1 (a11y floor). |
| KIT-19-06 | `readme.md:40` "No emoji … meaning is carried by Material Symbols icons and color"; all feedback is visual/text (state-copy matrices in `_features/*`, semantic color tones); grep: no `haptic`/`vibrate`/`sound` in kit | PASS | No sensory-only signal exists; feedback is always visual + text. |
| KIT-19-03 | No drag/reorder in product scope; ordering via SortSheet (documented) | ACCEPTED | Remediation — audit v5 fix loop. |
| KIT-19-05 | components.css .field/.cappbar__search-input/.search-dock__input :focus-visible ring | FIXED | Remediation — audit v5 fix loop. |

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
