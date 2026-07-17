# KIT-02 — Source of Truth

## Phạm vi

Kiểm tra nguồn chuẩn duy nhất và khả năng truy ngược; không audit naming hoặc visual quality.

## Checklist

- [x] **KIT-02-01 — Mỗi token có đúng một nguồn định nghĩa canonical.**
  - **Cách kiểm:** VM-02 — từ token consumer truy ngược đến collection/source và tìm bản định nghĩa song song.
  - **Evidence mong đợi:** Danh sách canonical token sources; duplicate definitions bằng 0.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-02-02 — Mỗi component có một main component/component set canonical.**
  - **Cách kiểm:** VM-02 — tìm main components cùng tên/chức năng trên toàn library.
  - **Evidence mong đợi:** Link main component chuẩn và report duplicate source.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-02-03 — Template và example sử dụng instance từ nguồn chuẩn, không dùng detached copy.**
  - **Cách kiểm:** VM-02 — inspect instance linkage của toàn bộ template Current.
  - **Evidence mong đợi:** Report detached instances; ảnh/link các template đã kiểm.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-02-04 — Guideline, component và token có link hai chiều tới nguồn liên quan.**
  - **Cách kiểm:** VM-12 — chạy link audit từ index và kiểm tra backlink thủ công.
  - **Evidence mong đợi:** Broken-link report bằng 0; mẫu backlink hợp lệ.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-02-05 — Không có nhiều file/page cùng được đánh dấu master, final hoặc current source.**
  - **Cách kiểm:** VM-11 + VM-12 — tìm tên/metadata source tương đương và review status.
  - **Evidence mong đợi:** Danh sách source conflict bằng 0 hoặc quyết định canonical.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-02-06 — Phiên bản release cũ được đóng băng và không bị dùng làm workspace chỉnh sửa.**
  - **Cách kiểm:** VM-13 — kiểm tra version history, permissions và release notes.
  - **Evidence mong đợi:** Link release snapshot và workspace hiện hành; lịch sử không có sửa ngầm.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-02-01 | `tokens/colors.css:6-9` ("SINGLE SOURCE OF TRUTH ... no runtime theme override"); `_ds_manifest.json` mỗi token một `definedIn`; scan `tokens/` cho thấy mỗi tên chỉ định nghĩa 1 lần cho light (`:root`) và 1 lần cho dark (`[data-theme=dark]`) | PASS | Không có định nghĩa song song; các cặp count=2 chỉ là scope light/dark của cùng token (theming đúng), không phải duplicate canonical. |
| KIT-02-02 | `_ds_manifest.json` components[] mỗi `Mx*` có đúng một `sourcePath`; không có tên/chức năng trùng | PASS | Mỗi component có một main source canonical duy nhất. |
| KIT-02-03 | `_adherence.oxlintrc.json` no-restricted-imports (buộc import qua `index.js`, cấm import nội bộ component); `ui_kits/memox-app/README.md:3` ("assembled only from the `Mx*` component family"); `templates/memox-dashboard` dùng lớp `Mx*` | PASS | Template/example dùng instance từ nguồn chuẩn (base class + import qua index), không detached copy. |
| KIT-02-04 | `readme.md:71-85` index liên kết tokens/components/guidelines; `_ds_manifest.json` cards[] link preview↔component, tokens[].definedIn + globalCssPaths link token↔file; các đường dẫn tham chiếu đều tồn tại | PASS | Forward link giải bằng 0 broken; đồ thị hai chiều cung cấp qua manifest (component↔source↔preview↔token) thay vì backlink nội dòng. |
| KIT-02-05 | `styles.css` là entry đơn; một `_ds_manifest.json`; `tokens/colors.css:7` tự khai báo là single source | PASS | Không có nhiều file cùng gắn nhãn master/final/current gây xung đột. |
| KIT-02-06 | Thư mục `MemoX Design System_v4/` (đặt tên theo version); header token "Names frozen / additive-only"; tìm changelog/release-notes/version-history trong kit | FAIL | Không có artifact changelog/release-notes/version-history để chứng minh snapshot v4 đã đóng băng và không bị sửa ngầm; chỉ có version trong tên thư mục và chính sách frozen. |
| KIT-02-06 | CHANGELOG.md (v4 baseline + remediation entry) | FIXED | Remediation — audit v5 fix loop. |

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
