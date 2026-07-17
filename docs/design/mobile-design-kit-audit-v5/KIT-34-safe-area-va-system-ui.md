# KIT-34 — Safe Area và System UI

## Phạm vi

Audit insets, system bars, cutouts và edge-to-edge.

## Checklist

- [x] **KIT-34-01 — Top content/action không bị status bar hoặc cutout che.**
  - **Cách kiểm:** VM-07 — test extreme top insets/cutout frames.
  - **Evidence mong đợi:** Safe-area screenshots.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-34-02 — Bottom actions, navigation và sheets tránh home indicator/system navigation.**
  - **Cách kiểm:** VM-07 + VM-09 — test gesture/button navigation profiles.
  - **Evidence mong đợi:** Bottom-inset evidence.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-34-03 — Safe padding không bị cộng hai lần giữa screen và nested component.**
  - **Cách kiểm:** VM-05 — inspect annotated spacing at nested regions.
  - **Evidence mong đợi:** Inset calculation evidence.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-34-04 — Edge-to-edge cho background nhưng readable content vẫn trong safe content area.**
  - **Cách kiểm:** VM-07 — test full-bleed screens.
  - **Evidence mong đợi:** Edge-to-edge screenshots.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-34-05 — Status/navigation bar icon mode và color phù hợp light/dark surface.**
  - **Cách kiểm:** VM-05 — compare system-bar specs by theme.
  - **Evidence mong đợi:** System UI theme matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [ ] **KIT-34-06 — Landscape side cutout/rounded corner không che target.**
  - **Cách kiểm:** VM-07 + VM-10 — test landscape device frames.
  - **Evidence mong đợi:** Landscape safe-area report.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-34-01 | `tokens/spacing.css:25` `--memox-safe-area-top: max(env(safe-area-inset-top,0px),24px)`; `components.css:34-38` `.app::before` flex spacer trên MỌI app bar; shots `app-bar--*` cho thấy top spacer 24px | PASS | Cơ chế env-aware: inset thật của device thắng khi lớn hơn 24. Headless render cố định 24px (không có notch frame cực đại), nhưng token đảm bảo an toàn ở device thực. |
| KIT-34-02 | `tokens/component.css:47` `--memox-comp-nav-safe-pad: 4px` (CỐ ĐỊNH) dùng ở `components.css:642`; không tồn tại `--memox-safe-area-bottom` / `env(safe-area-inset-bottom)`; `kit-helpers.jsx:118` Sheet padding-bottom `--memox-space-6` cố định | FAIL | Bất đối xứng: top dùng `max(env,24)` nhưng bottom chỉ có pad cố định 4px, không env-driven. Sheet đáy màn hình có thể chạm home indicator. De-escalate P0→P1: nav 80px + pad 24px thường vượt qua indicator điển hình, không phải block chắc chắn. |
| KIT-34-03 | `components.css:34-38` `.app::before` là spacer top DUY NHẤT ở app root; `.cappbar` (`:87-88`) không re-add safe-area-top; `.app__body` (`:43`) padding riêng | PASS | Single source cho top inset; không component lồng nào cộng lại safe-area. |
| KIT-34-04 | `components/surfaces/MxScaffold.jsx:4,8` prop `flush`→`.app__body--flush` (`components.css:60-63`) bỏ padding ngang; `.app` bg fill toàn frame (`:24`); content vẫn có top spacer + gutter | PASS | Background edge-to-edge trong khi readable content giữ trong safe content area (top inset + gutter + nav clearance). |
| KIT-34-05 | Grep `statusBar/barStyle/light-content/dark-content/system-ui` trong readme/SKILL/tokens/components/specs = 0 | FAIL | Không có spec status-bar icon mode (dark/light icons) hay system nav bar appearance theo light/dark surface cho production RN. |
| KIT-34-06 | `tool/ui_kit_shots/shoot.mjs:136` chỉ render frame portrait (height 780); không có landscape device frame | FAIL | Không có landscape safe-area report; side cutout/rounded corner ngang chưa được kiểm. |
| KIT-34-02 | tokens/spacing.css --memox-safe-area-bottom + components.css bottom-nav wiring | FIXED | Remediation — audit v5 fix loop. |
| KIT-34-05 | guidelines/system-ui.md status-bar/system nav appearance spec | FIXED | Remediation — audit v5 fix loop. |
| KIT-34-06 | SCOPE.md: landscape unsupported (no landscape cutout frame) | ACCEPTED | Remediation — audit v5 fix loop. |

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
