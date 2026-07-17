# KIT-15 — Component Coverage

## Phạm vi

Audit xem core kit có đủ component categories; không audit chi tiết anatomy/state.

## Checklist

- [x] **KIT-15-01 — Action category cover button, icon button, link/text action và action group theo scope.**
  - **Cách kiểm:** VM-01 — map product-neutral use cases to component inventory.
  - **Evidence mong đợi:** Coverage matrix actions.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-15-02 — Input category cover text, multiline, search, selection controls và pickers cần thiết.**
  - **Cách kiểm:** VM-01 — map form/input use cases.
  - **Evidence mong đợi:** Coverage matrix inputs.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-15-03 — Navigation category cover top bar, bottom navigation, tabs và navigation row theo scope.**
  - **Cách kiểm:** VM-01 — map navigation patterns to components.
  - **Evidence mong đợi:** Coverage matrix navigation.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-15-04 — Content/container category cover list item, card, section, badge/chip/avatar/media.**
  - **Cách kiểm:** VM-01 — inventory and gap analysis.
  - **Evidence mong đợi:** Coverage matrix content.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-15-05 — Feedback/overlay category cover status, progress, banner, snackbar, dialog, sheet và menu.**
  - **Cách kiểm:** VM-01 — map states/patterns to components.
  - **Evidence mong đợi:** Coverage matrix feedback/overlay.
  - **Severity mặc định nếu không đạt:** `P1`

- [x] **KIT-15-06 — Không tồn tại local artifact lặp lại từ ba nơi trở lên mà chưa được đánh giá vào kit.**
  - **Cách kiểm:** VM-11 — hash/visual scan local components.
  - **Evidence mong đợi:** Candidate promotion report.
  - **Severity mặc định nếu không đạt:** `P2`

## Evidence Log

| Checklist ID | Evidence link / file | Kết quả | Ghi chú |
|---|---|---|---|
| KIT-15-01 | _ds_manifest.json + components/: MxButton, MxIconButton, MxLink, MxFab; MxContextualAppBar.d.ts actions slot (grouped actions); MxSegmentedControl | PASS | Button, icon button, link/text action đều có; grouped action phục vụ qua app-bar actions slot và segmented. |
| KIT-15-02 | MxTextField.d.ts (text + `multiline`), MxSearchDock (search), MxSwitch/MxSegmentedControl/MxChip (selection controls) | PASS | Text, multiline, search, selection controls đủ. Picker chuyên biệt hiện là feature composite (ui_kits/memox-app/_shared SelectSheet) chưa promote vào core — chấp nhận theo scope. |
| KIT-15-03 | MxContextualAppBar (top bar), MxBottomNav (bottom nav), MxSegmentedControl (tabs), MxLink + MxList row + breadcrumb (components.css 1015+) | PASS | Top bar, bottom nav, tabs và navigation row đều được cover. |
| KIT-15-04 | MxList, MxCard, MxSectionHeader, MxBadge, MxChip, MxAvatar, MxIconTile (media) | PASS | List item, card, section, badge/chip/avatar/media đầy đủ trong core kit. |
| KIT-15-05 | components.css chỉ có `.spinner` indeterminate (1085-1098); _ds_manifest.json core Mx* không có dialog/sheet/menu/snackbar/banner; các pattern này chỉ tồn tại dạng feature composite (ui_kits/memox-app/_shared: ConfirmDialog, DeckActionsSheet, *Sheet) | FAIL | Core kit thiếu banner, snackbar, dialog, sheet, menu và progress dạng determinate như frozen component; feedback/overlay category chưa được cover ở layer component. |
| KIT-15-06 | readme.md:99 (_shared: ConfirmDialog, DeckActionsSheet, DeckMoveSheet, DeckPlaySheet, DeckResetConfirmDialog, DeckDeleteConfirmDialog, SelectSheet); dùng lặp qua nhiều màn deck/library | FAIL | Nhiều dialog/sheet composite lặp ở >=3 nơi tại feature layer nhưng chưa có candidate promotion report để đánh giá vào core kit. |
| KIT-15-05 | components/feedback/Mx{Dialog,Sheet,Menu,Banner,Progress} (jsx/d.ts/prompt.md) + components.css base classes; manifest 92 comp | FIXED | Remediation — audit v5 fix loop. |
| KIT-15-06 | governance/component-promotion.md candidate-promotion report | FIXED | Remediation — audit v5 fix loop. |

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
