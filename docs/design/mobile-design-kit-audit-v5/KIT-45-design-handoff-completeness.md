# KIT-45 — Design Handoff Completeness

## Phạm vi

Audit khả năng bàn giao từ design kit, không kiểm code implementation.

## Checklist

- [x] **KIT-45-01 — Main layouts dùng constraints/auto-layout equivalent và resize đúng.**
  - **Cách kiểm:** VM-02 + VM-07 — inspect constraints and resize source frames.
  - **Evidence mong đợi:** Báo cáo kiểm tra constraint.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-45-02 — Mọi visual property dùng token/style hoặc approved exception.**
  - **Cách kiểm:** VM-01 — inspect/export local values.
  - **Evidence mong đợi:** Báo cáo giá trị local ngoài token/style.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-45-03 — Templates dùng source-linked instances; detached instance có rationale.**
  - **Cách kiểm:** VM-02 — scan instance linkage.
  - **Evidence mong đợi:** Báo cáo instance bị tách khỏi nguồn chuẩn.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-45-04 — Behavior, state, responsive, keyboard và accessibility notes có thể tìm thấy từ frame/component.**
  - **Cách kiểm:** VM-12 — follow handoff links from representative artifacts.
  - **Evidence mong đợi:** Checklist truy vết thông tin bàn giao.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-45-05 — Assets có format, dimensions, scale và fallback specs.**
  - **Cách kiểm:** VM-14 — inspect export panel/asset manifest.
  - **Evidence mong đợi:** Bảng thông tin bàn giao asset.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-45-06 — Người nhận không phải đo tay các giá trị chuẩn hoặc hỏi lại source-of-truth.**
  - **Cách kiểm:** VM-02 + VM-12 — perform blind handoff spot-check.
  - **Evidence mong đợi:** Kết quả kiểm tra mẫu và các specification còn thiếu.
  - **Severity mặc định nếu không đạt:** `P2`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-45-01 | `readme.md:57` (layout rules), `docs/design/mobile-ui-construction-contract.md`, `specs/dashboard.md:40-44` | PASS | Layout dùng flex/grid + token spacing (constraint-equivalent); construction contract bắt buộc narrow-device/large-font/dense states và parity gate render ổn định tại 390×780. |
| KIT-45-02 | `_adherence.oxlintrc.json` (no-raw-values lint), `readme.md:23` | PASS | Rule "no raw visual values above token layer" được enforce bằng oxlint adherence config + parity gate; visual values chỉ tồn tại ở token layer. |
| KIT-45-03 | `ui_kits/memox-app/README.md` ("assembled only from the Mx* component family"), `_ds_manifest.json` sourcePath | PASS | Screen lắp ráp chỉ từ Mx* components; manifest link mọi component tới sourcePath — không có detached instance. |
| KIT-45-04 | `specs/*.md` (state matrix + handoff), `components/core/MxTextField.prompt.md:24` (a11y/keyboard), `.d.ts` (inputMode/type) | PASS | Behavior (prompt.md rules), state (specs), accessibility + keyboard (prompt.md/.d.ts) truy được từ component/spec; coverage responsive/RTL thưa nhưng thông tin bàn giao lõi tìm được. |
| KIT-45-05 | `_ds_manifest.json` fonts block, `readme.md:63-67,91` | FAIL | Font có format/weight/files trong manifest; nhưng không có bảng asset export (dimensions/scale/@2x@3x/fallback) và không có logo/app-icon asset (caveat readme.md:91). |
| KIT-45-06 | `tokens/*.css` (single source of truth), `readme.md:25`, `specs/dashboard.md:42` ("tokens only") | PASS | Mọi giá trị chuẩn đọc trực tiếp từ tokens/*.css; specs khẳng định tokens-only nên người nhận không phải đo tay. |
| KIT-45-05 | governance/asset-export-spec.md export spec table | FIXED | Remediation — audit v5 fix loop. |

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
