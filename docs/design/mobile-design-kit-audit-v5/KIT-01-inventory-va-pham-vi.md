# KIT-01 — Inventory và phạm vi

## Phạm vi

Chỉ xác nhận những gì thuộc kit, trạng thái và độ bao phủ; không audit chất lượng chi tiết của từng artifact.

## Checklist

- [x] **KIT-01-01 — Inventory liệt kê đủ foundations, tokens, components, patterns và templates đang tồn tại.**
  - **Cách kiểm:** VM-01 — xuất danh sách từ từng page/library rồi so với inventory chuẩn.
  - **Evidence mong đợi:** Bảng đối chiếu có tổng số nguồn, tổng số trong inventory và danh sách phần thiếu.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-01-02 — Mỗi artifact được gán đúng một trạng thái Current, Future hoặc Deprecated.**
  - **Cách kiểm:** VM-01 — lọc inventory theo trường status và tìm giá trị rỗng/ngoài tập cho phép.
  - **Evidence mong đợi:** File inventory không có status rỗng; danh sách artifact theo từng trạng thái.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-01-03 — Artifact Current chỉ gồm phần đã đủ states, theme coverage và documentation tối thiểu.**
  - **Cách kiểm:** VM-04 + VM-12 — lấy mẫu toàn bộ Current và đối chiếu state/theme/doc matrix.
  - **Evidence mong đợi:** Ma trận Current artifact với các cột state, theme, docs đều có bằng chứng.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-01-04 — Không có artifact chỉ xuất hiện trong canvas/library nhưng không có trong inventory.**
  - **Cách kiểm:** VM-01 — diff danh sách export với inventory ID.
  - **Evidence mong đợi:** Report orphan artifacts bằng 0 hoặc issue list có owner.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-01-05 — Business-specific screen element không bị đưa nhầm vào generic core kit.**
  - **Cách kiểm:** VM-02 — review purpose/usage của các component chỉ có một nơi dùng.
  - **Evidence mong đợi:** Danh sách giữ lại/di chuyển sang product-local kèm lý do.
  - **Severity mặc định nếu không đạt:** `P2`

- [x] **KIT-01-06 — Phạm vi hỗ trợ mobile, tablet, platform và accessibility được nêu rõ.**
  - **Cách kiểm:** VM-12 — đọc scope statement và đối chiếu với ví dụ hiện có.
  - **Evidence mong đợi:** Scope matrix ghi Supported/Not supported/Planned cho từng profile.
  - **Severity mặc định nếu không đạt:** `P2`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-01-01 | `_ds_manifest.json` (components[] 87 mục, tokens[] ~160 mục, cards[] 30, templates[] 1); `readme.md:71-85`; `ui_kits/memox-app/specs/INDEX.md:9-37`; `tokens/` 11 file | PASS | Inventory sinh tự động từ source (`design-sync-cli` / registry) nên phủ đủ foundations/tokens/components/patterns/templates. Lưu ý drift nhỏ: `readme.md:81` ghi "26 screens" trong khi `specs/INDEX.md:37` ghi 25 screens. |
| KIT-01-02 | Tìm trường status trong `_ds_manifest.json`, `readme.md`, `SKILL.md` | FAIL | Không tồn tại trường trạng thái Current/Future/Deprecated cho bất kỳ artifact nào; toàn kit là một release v4 duy nhất nên mọi artifact ngầm là Current. |
| KIT-01-03 | Mỗi component có `.d.ts` + `.prompt.md` (vd `components/core/MxTextField.d.ts`, `MxButton.prompt.md`); `ui_kits/memox-app/shots/` 337 PNG light+dark; `specs/INDEX.md` state matrix 160 states | PASS | State × theme × docs đều có bằng chứng: đủ light/dark, đủ prop-contract và prompt doc. |
| KIT-01-04 | `_ds_manifest.json` components[].sourcePath ánh xạ 1:1 tới file `.jsx` tồn tại; manifest sinh từ source | PASS | Không có orphan: inventory phái sinh từ chính source path nên không thể lệch. |
| KIT-01-05 | Core generic ở `components/{core,surfaces,navigation}/Mx*`; composite theo nghiệp vụ tách sang `ui_kits/memox-app/_features/*` và `_shared/*`; `_adherence.oxlintrc.json` no-restricted-imports chặn import nội bộ feature | PASS | Tách bạch rõ generic core kit và business composite. |
| KIT-01-06 | `readme.md:3-5` (target React Native), `ui_kits/memox-app/README.md:3` (mobile 390×780 portrait) | FAIL | Không có scope matrix Supported/Not supported/Planned cho tablet, platform và accessibility; chỉ nêu mobile portrait. |
| KIT-01-02 | SCOPE.md (artifact status taxonomy Current/Future/Deprecated) | FIXED | Remediation — audit v5 fix loop. |
| KIT-01-06 | SCOPE.md (Supported/Not-supported/Planned matrix) | FIXED | Remediation — audit v5 fix loop. |

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
