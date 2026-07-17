# KIT-21 — Component Accessibility

## Phạm vi

Audit accessibility ở cấp component; end-to-end task thuộc KIT-42.

## Checklist

- [x] **KIT-21-01 — Mỗi interactive component có role, accessible name, value và state khi relevant.**
  - **Cách kiểm:** VM-10 — inspect component semantics spec/examples.
  - **Evidence mong đợi:** Component semantics matrix.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-21-02 — Focus indicator thấy rõ và focus order trong composite component hợp lý.**
  - **Cách kiểm:** VM-10 — keyboard walkthrough composite components.
  - **Evidence mong đợi:** Focus screenshots and order list.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-21-03 — Selected, checked, expanded, disabled, loading và error được announce.**
  - **Cách kiểm:** VM-10 — inspect state announcements.
  - **Evidence mong đợi:** Announcement matrix.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-21-04 — Error/help text được programmatically associated với field.**
  - **Cách kiểm:** VM-10 — inspect form component semantics.
  - **Evidence mong đợi:** Association evidence.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-21-05 — Touch target và gesture alternative đạt yêu cầu motor accessibility.**
  - **Cách kiểm:** VM-10 + VM-09 — measure and execute alternative path.
  - **Evidence mong đợi:** Target/alternative report.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-21-06 — Component chịu text scaling 200% và reduced motion.**
  - **Cách kiểm:** VM-08 + VM-15 — run stress profiles.
  - **Evidence mong đợi:** Accessibility profile screenshots.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-21-01 | `MxSwitch.jsx:11-13` role=switch+aria-checked+aria-label; `MxSegmentedControl.jsx:8,15` radiogroup/radio+aria-checked+aria-label; `MxTextField.jsx:22-28,41-47` labelled input+aria-invalid/required; `MxIconButton.jsx:10` aria-label; `MxFab.jsx:11` aria-label; `MxCard.jsx:13-14` role=button+aria-label; `MxSectionHeader.jsx:16` role=button+aria-label | PASS | Every interactive component exposes a role + accessible name, and the relevant value/state (checked/invalid/required) where applicable. |
| KIT-21-02 | Focus rings present on `.btn`/`.icon-btn`/`.fab` (`components.css:337-339,474-476,573-575`). Missing on text inputs: `.field:928` `outline:none` no `:focus` ring, `.cappbar__search-input:196`, `.search-dock__input:612` (ring only on prop-driven `.search-dock--focused:621`). Focus order = DOM order | FAIL | Text inputs have no visible focus indicator on keyboard focus (only caret). P1 (down from P0, a11y floor): scoped to inputs; buttons/fab/segmented have rings; component-level. |
| KIT-21-03 | Announced: checked (`MxSwitch.jsx:12`), invalid/error (`MxTextField.jsx:25`, `:47` role=alert), disabled (`disabled` attr on buttons/switch/field). NOT announced: bottom-nav selected (`MxBottomNav.jsx:10-20` visual `--active` only, no aria-current), expanded (`components.css:1065-1079` `.card-more` toggle, no aria-expanded), loading (`components.css:1088-1097` `.spinner` + audio-generating, no aria-busy/role=status) | FAIL | Selected/expanded/loading states are not programmatically announced. P1 (down from P0): checked/disabled/error already announced; gaps limited to 3 states. |
| KIT-21-04 | `MxTextField.jsx:20-27` builds `helpId` and wires `aria-describedby`; `:41` `htmlFor`/`id` pairing; `:46-48` error `id={helpId}` + `role="alert"`, helper `id={helpId}`; `MxTextField.prompt.md:24` documents the association contract | PASS | Error/help text is programmatically associated (aria-describedby + role=alert + htmlFor/id). |
| KIT-21-05 | `tokens/spacing.css:29` `--memox-touch-min:48px`; `components.css:979-1013` `::after` hit-area overlays lift chip/switch/btn--sm/icon-btn--sm/segmented/section-action/accent-swatch to 48px; `:320,414,924` min-height touch-min on btn/link/field; gesture alt: `review-mode` swipe has study-flow **Next** button | PASS | Targets meet ≥48px (M3) and the only gesture has a button alternative. |
| KIT-21-06 | Reduced-motion covers only `components.css:206` (.cappbar) + `:1098` (.spinner); press-scale transforms, card/sheet transitions and skeleton pulse (`motion.css:17`) are NOT reduced. No 200% text-scale renders among 336 shots (grep large/font/scale = 0) | FAIL | Reduced-motion coverage is partial and there is no text-scaling-200% verification evidence. P1 (default). |
| KIT-21-02 | components.css text-input :focus-visible ring | FIXED | Remediation — audit v5 fix loop. |
| KIT-21-03 | aria-expanded on collapsibles + role=status/aria-busy on SyncBlock + MxBottomNav aria-current | FIXED | Remediation — audit v5 fix loop. |
| KIT-21-06 | global reduced-motion reset done; 200% text-scaling shots pending CI | PARTIAL | Remediation — audit v5 fix loop. |
| KIT-21-06 | tool/ui_kit_shots/shoot.mjs FONT_SCALES incl 2.0; full matrix 100-200% × 320-430px sạch sau khi wrap dialog action row; global reduced-motion reset (motion.css); evidence/200pct-dialog-fixed--*.png | FIXED | Component chịu 200% text scaling (không cắt/khóa) + reduced-motion reset toàn cục. Xem governance/coverage-report.md. |

## Kết luận nhóm

```text
Final status: PASS
Open P0: 
Open P1: 
Open P2: 
Open P3: 
Reviewed by: Claude (automated kit audit + remediation)
Reviewed date: 2026-07-16
```
