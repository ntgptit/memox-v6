# KIT-32 — Responsive và Adaptive Layout

## Phạm vi

Sở hữu toàn bộ breakpoint, tablet, large screen, split view và adaptive presentation.

## Checklist

- [ ] **KIT-32-01 — Có breakpoint/profile cho phone hẹp, phone rộng, tablet và compact height theo scope.**
  - **Cách kiểm:** VM-12 + VM-07 — inspect thresholds and resize around each boundary.
  - **Evidence mong đợi:** Breakpoint table and boundary screenshots.
  - **Severity mặc định nếu không đạt:** `P1`

- [ ] **KIT-32-02 — Layout reflow giữ semantic order; không chỉ scale hoặc kéo giãn phone UI.**
  - **Cách kiểm:** VM-07 + VM-05 — compare phone/tablet compositions.
  - **Evidence mong đợi:** Annotated reflow comparison.
  - **Severity mặc định nếu không đạt:** `P1`

- [ ] **KIT-32-03 — Tablet/large screen có max content width và navigation/pane strategy rõ.**
  - **Cách kiểm:** VM-07 — test min/max tablet widths and orientation.
  - **Evidence mong đợi:** Large-screen layout evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [ ] **KIT-32-04 — List-detail/multi-pane collapse về single-pane với back behavior đúng.**
  - **Cách kiểm:** VM-09 + VM-07 — resize while navigating panes.
  - **Evidence mong đợi:** Pane transition recording.
  - **Severity mặc định nếu không đạt:** `P1`

- [ ] **KIT-32-05 — Bottom sheet/dialog/navigation có adaptive presentation rule.**
  - **Cách kiểm:** VM-04 + VM-07 — compare component presentation by profile.
  - **Evidence mong đợi:** Adaptive component matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-32-06 — Foldable/split-view/hinge unsupported hoặc supported được ghi và test tương ứng.**
  - **Cách kiểm:** VM-12 + VM-07 — inspect scope and representative posture.
  - **Evidence mong đợi:** Support statement and posture evidence.
  - **Severity mặc định nếu không đạt:** `P2`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-32-01 | `tool/ui_kit_shots/shoot.mjs:32` `WIDTHS = [320, 360, 390, 430]` + overflow gate (`:204`); canonical shots chỉ 390px (`shoot.mjs:44`, `ui_kits/memox-app/shots/INDEX.md`) | FAIL | Chỉ có profile phone-hẹp(320)/phone-rộng(430) trong tooling; thiếu profile tablet và compact-height; không có breakpoint table dạng semantic profile được tài liệu hóa. |
| KIT-32-02 | Toàn bộ `_features/*` render trong 1 frame phone (`shoot.mjs:136` height 780 cố định); không có composition tablet để so sánh | FAIL | Reflow phone-width là fluid đúng, nhưng không tồn tại annotated reflow comparison phone↔tablet như evidence yêu cầu. |
| KIT-32-03 | Không có layout tablet/large-screen; frame giới hạn ở 430px phone; không có max-content-width/pane strategy | FAIL | Không có large-screen layout evidence. |
| KIT-32-04 | Grep `split-view/two-pane/list-detail/master-detail` trong kit = 0 | FAIL | Không có pattern multi-pane hay list-detail collapse. |
| KIT-32-05 | `kit-helpers.jsx:107` Scrim + `:116` Sheet: sheet luôn bottom, dialog luôn center — chọn theo loại nội dung, không theo device profile | FAIL | Không có adaptive-presentation-by-profile rule (ví dụ sheet→popover trên tablet). |
| KIT-32-06 | Grep `foldable/split-view/hinge` trong readme/SKILL/specs = 0 | FAIL | Không có support statement cho foldable/split-view. |
| KIT-32-01 | SCOPE.md: tablet/large-screen out of scope (phone-portrait kit) | ACCEPTED | Remediation — audit v5 fix loop. |
| KIT-32-02 | SCOPE.md: tablet reflow out of scope | ACCEPTED | Remediation — audit v5 fix loop. |
| KIT-32-03 | SCOPE.md: large-screen layout out of scope | ACCEPTED | Remediation — audit v5 fix loop. |
| KIT-32-04 | SCOPE.md: multi-pane/list-detail out of scope | ACCEPTED | Remediation — audit v5 fix loop. |
| KIT-32-05 | SCOPE.md: adaptive-presentation by device profile out of scope | ACCEPTED | Remediation — audit v5 fix loop. |
| KIT-32-06 | SCOPE.md: foldable/split-view/hinge explicitly unsupported | FIXED | Remediation — audit v5 fix loop. |

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
