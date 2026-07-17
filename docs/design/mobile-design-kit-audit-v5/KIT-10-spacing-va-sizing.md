# KIT-10 — Spacing và Sizing

## Phạm vi

Audit spacing scale usage, internal gaps và touch sizing; responsive breakpoints thuộc KIT-32.

## Checklist

- [x] **KIT-10-01 — Screen padding, section gap và item gap đều lấy từ scale đã định nghĩa.**
  - **Cách kiểm:** VM-01 + VM-05 — inspect representative screens và compare values.
  - **Evidence mong đợi:** Annotated spacing audit với token names.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-10-02 — Component internal padding và icon-label gap nhất quán giữa variants.**
  - **Cách kiểm:** VM-04 — compare button/input/list/card variants.
  - **Evidence mong đợi:** Variant spacing matrix.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-10-03 — Không có giá trị spacing/sizing ngoài scale mà thiếu exception record.**
  - **Cách kiểm:** VM-01 — export numeric values và diff allowed scale.
  - **Evidence mong đợi:** Outlier report và exception links.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-10-04 — Touch target đạt tối thiểu 44×44 pt hoặc 48×48 dp theo platform profile.**
  - **Cách kiểm:** VM-10 — đo hit area, không chỉ visual bounds.
  - **Evidence mong đợi:** Touch-target table theo component/profile.
  - **Severity mặc định nếu không đạt:** `P0`

- [x] **KIT-10-05 — Khoảng cách giữa adjacent targets đủ tránh chạm nhầm.**
  - **Cách kiểm:** VM-10 + VM-05 — đo các toolbar, list actions và dialog actions.
  - **Evidence mong đợi:** Annotated target-spacing screenshots.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-10-06 — Icon, avatar, control và media size dùng scale riêng phù hợp, không trộn spacing token tùy tiện.**
  - **Cách kiểm:** VM-01 + VM-04 — inspect property bindings.
  - **Evidence mong đợi:** Sizing-token usage report theo component category.
  - **Severity mặc định nếu không đạt:** `P1`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-10-01 | components.css:43-47,215-223,276-283; tokens/spacing.css; guidelines/spacing-scale.html | PASS | app__body padding space-4/gutter 16, section gap space-6 (24); card padding space-6, gap space-3; section wrapper gap space-3 — đều từ scale. |
| KIT-10-02 | components.css:315-356,697-714 | PASS | Btn variant scale padding trên token (space-6/4/7), gap space-2; chip gap space-2 pad space-4; nhất quán giữa variant. |
| KIT-10-03 | components.css:149-174,182 (raw px chưa tag); đối chiếu tokens/spacing.css + size.css | FAIL | Raw px chưa tag `raw-ok` trong chrome của cappbar__badge (5/7/16/10/4px) và cappbar__search height 40px; hit-inset thì đã tag raw-ok (1007-1013). Giới hạn trong chrome app-bar, một số map về size token (16≈size-xs, 40=size-sm). |
| KIT-10-04 | components.css:315-320,455-462,409-415,988-1013; tokens/spacing.css:29 | PASS | touch-min 48; btn/icon-btn/link ≥48; control dưới 48 có overlay `::after` mở rộng tới 48; fab 56. |
| KIT-10-05 | components.css:104-110,632-663,983-986; ui_kits/memox-app/shots (action-sheet/toolbar) | PASS | Gap giữa target dùng token (appbar actions gap space-2, nav space-around); overlay hit được phép chồng gap theo M3; shot toolbar/action-sheet xác nhận. |
| KIT-10-06 | tokens/icon-size.css; tokens/size.css; tokens/component.css; components.css:478-521,881-918 | PASS | Scale riêng cho icon (18/22/28/32), avatar/tile/media (size.css, comp dims); component bind vào icon-size/comp-* không dùng spacing token. |
| KIT-10-03 | components.css cappbar badge/search tokenized | FIXED | Remediation — audit v5 fix loop. |

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
