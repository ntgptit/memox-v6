# KIT-40 — Visual Consistency

## Phạm vi

Audit đồng nhất cross-component/cross-pattern, không thay thế từng checklist chuyên môn.

## Checklist

- [x] **KIT-40-01 — Cùng semantic role dùng cùng token trên mọi component Current.**
  - **Cách kiểm:** VM-03 — usage scan by semantic role.
  - **Evidence mong đợi:** Role-to-token consistency report.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-40-02 — Component cùng chức năng không có spacing, typography hoặc icon khác nhau ngoài variant policy.**
  - **Cách kiểm:** VM-05 + VM-04 — compare component families.
  - **Evidence mong đợi:** Family comparison contact sheet.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-40-03 — Cùng screen pattern dùng chung keyline, section rhythm và action hierarchy.**
  - **Cách kiểm:** VM-05 — annotate template set.
  - **Evidence mong đợi:** Pattern consistency report.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-40-04 — Light/dark/platform adaptations giữ state parity.**
  - **Cách kiểm:** VM-04 — compare state matrices across profiles.
  - **Evidence mong đợi:** Ma trận trạng thái giữa các profile.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-40-05 — Không có local override lặp lại trở thành visual dialect riêng.**
  - **Cách kiểm:** VM-11 — cluster overrides by property/value.
  - **Evidence mong đợi:** Override-cluster report.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-40-06 — Known exceptions có reason, owner và target thay vì bị coi là chuẩn mới.**
  - **Cách kiểm:** VM-13 — review exception register.
  - **Evidence mong đợi:** Danh sách ngoại lệ hiện hành.
  - **Severity mặc định nếu không đạt:** `P3`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-40-01 | `components.css` (mọi role dùng `--memox-<role>`); `_adherence.oxlintrc.json` (lint chặn raw value) | PASS | Cùng semantic role ánh xạ cùng token trên toàn bộ Mx*. |
| KIT-40-02 | `_ds_manifest.json` (18 component canonical duy nhất); `components/**` (variant = modifier) | PASS | Không có duplicate cùng chức năng với spacing/typography/icon khác nhau. |
| KIT-40-03 | `shots/*.png` (mọi screen dùng MxScaffold + MxContextualAppBar 56 + MxBottomNav 80 + padding 16); `audit/_sheets/17-edge-b.png` | PASS | Keyline, section rhythm và action hierarchy nhất quán. |
| KIT-40-04 | `ui_kits/memox-app/shots/` (337 shot, mọi state có cặp `--light`/`--dark`) | PASS | State parity giữ đủ giữa light và dark; kit đơn platform. |
| KIT-40-05 | `ui_kits/memox-app/_features/**/*.jsx` (0 raw hex; inline style dùng `var(--memox-*)`) | PASS | Không có raw-value dialect ở screen; `.card.html` là specimen tài liệu cô lập. |
| KIT-40-06 | `readme.md` KNOWN CAVEATS (no logo asset, placeholder data); không có exception register có owner/target | FAIL | Ngoại lệ ghi lý do nhưng thiếu owner/target/governance metadata. |
| KIT-40-06 | governance/exception-register.md (caveats given owner/target/expiry) | FIXED | Remediation — audit v5 fix loop. |

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
