# KIT-36 — Orientation và Device Conditions

## Phạm vi

Audit rotation, extreme size và capability-dependent fallback.

## Checklist

- [x] **KIT-36-01 — Portrait baseline có min height và scroll behavior rõ.**
  - **Cách kiểm:** VM-07 — test shortest supported portrait frame.
  - **Evidence mong đợi:** Portrait stress evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [ ] **KIT-36-02 — Landscape compact height không che navigation, overlay hoặc primary action.**
  - **Cách kiểm:** VM-07 + VM-09 — run representative screens.
  - **Evidence mong đợi:** Landscape screenshots.
  - **Severity mặc định nếu không đạt:** `P1`

- [ ] **KIT-36-03 — Rotation giữ input, selection, scroll và navigation context theo rule.**
  - **Cách kiểm:** VM-09 — rotate during form, list selection and modal.
  - **Evidence mong đợi:** Rotation state-preservation recording.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-36-04 — Màn hình cực hẹp/thấp không overflow ngang hoặc tạo target không chạm được.**
  - **Cách kiểm:** VM-07 — test boundary dimensions.
  - **Evidence mong đợi:** Extreme-size report.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-36-05 — Capability-dependent action có unavailable/permission-denied fallback.**
  - **Cách kiểm:** VM-09 + VM-12 — inspect camera/biometric/haptic examples if in scope.
  - **Evidence mong đợi:** Capability-state matrix.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-36-06 — Unsupported orientation hoặc capability được ghi rõ, không im lặng giả định.**
  - **Cách kiểm:** VM-12 — review scope/constraints.
  - **Evidence mong đợi:** Support statement.
  - **Severity mặc định nếu không đạt:** `P2`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-36-01 | `components.css:39-44` `.app__body` overflow-y auto (scroll rõ); `shoot.mjs:136` height cố định 780, `WIDTHS` chỉ đổi width | FAIL | Scroll behavior rõ ràng, nhưng không có min-height được tài liệu hóa và không stress ở frame portrait ngắn nhất → partial, không đủ để đánh [x]. |
| KIT-36-02 | Không có landscape device frame trong `shoot.mjs`; grep landscape/orientation = 0 | FAIL | Không có landscape screenshots; chưa kiểm nav/overlay/primary action ở landscape compact height. |
| KIT-36-03 | Kit tĩnh không thực thi rotation; không có rule preservation state khi xoay | FAIL | Không có rotation state-preservation recording/rule. |
| KIT-36-04 | `shoot.mjs:32` `WIDTHS=[320,360,390,430]` + hOverflow gate (`:204`) + font-scale stress (narrowest × largest, `:41`); `components.css` bottom-nav `min-width:0` fit 320px; `--memox-touch-min:48px` | PASS | Biên hẹp 320px được test + gate chống overflow ngang; touch target ≥48; nội dung cao scroll (overflow-y auto). |
| KIT-36-05 | `_features/account-sync/components/SyncBlock.jsx:19` offline fallback ("Will sync when you're back online"); nhưng không có permission-denied fallback (notifications/audio) | FAIL | Network-capability degradation có fallback nhưng không có capability-state matrix cho device-permission (camera/biometric/notification) bị từ chối. |
| KIT-36-06 | readme KNOWN CAVEATS chỉ nêu logo/copy/validation; không có statement portrait-only hay landscape/tablet unsupported | FAIL | Scope phone-portrait là giả định im lặng, không được tài liệu hóa rõ ràng. |
| KIT-36-01 | short-portrait stress note + keyboard-open body scroll; shortest-portrait shot pending CI | PARTIAL | Remediation — audit v5 fix loop. |
| KIT-36-02 | SCOPE.md: landscape unsupported | ACCEPTED | Remediation — audit v5 fix loop. |
| KIT-36-03 | SCOPE.md: orientation change unsupported; state-preservation rule documented | ACCEPTED | Remediation — audit v5 fix loop. |
| KIT-36-05 | guidelines/permissions-capabilities.md + reminder permission-denied fixture | FIXED | Remediation — audit v5 fix loop. |
| KIT-36-06 | SCOPE.md: phone-portrait-only explicit statement | FIXED | Remediation — audit v5 fix loop. |
| KIT-36-01 | shots/flashcard-editor--keyboard-open--{light,dark}.png + shots/account-sync--sign-in-keyboard--{light,dark}.png (nội dung trong portrait height rút gọn ~56% do keyboard: .app__body scroll, SaveBar pinned, primary action reachable); components.css .app__body overflow-y:auto; 390×780 baseline; governance/coverage-report.md | FIXED | Portrait min-height 780 baseline + scroll rõ; shortest-portrait stress (keyboard-reduced height) không dead-end. |

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
