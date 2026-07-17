# Verification Methods

Các mã dưới đây được tham chiếu từ từng checklist để giảm lặp và giảm token.

## VM-01

Inventory/export scan — xuất danh sách token, component, style hoặc asset từ công cụ thiết kế rồi đối chiếu inventory.

## VM-02

Source-link inspection — mở trực tiếp nguồn chuẩn, instance và tài liệu liên quan để kiểm tra đường dẫn và quyền sở hữu.

## VM-03

Token mapping diff — so sánh alias/mapping giữa primitive, semantic, component token và các theme.

## VM-04

Component matrix review — lập ma trận component × variant × state × size × theme và kiểm tra ô thiếu.

## VM-05

Visual comparison — đặt các mẫu cạnh nhau trên cùng viewport/theme để phát hiện sai hierarchy, spacing hoặc state.

## VM-06

Contrast measurement — đo cặp foreground/background bằng công cụ tính contrast theo WCAG tương đương.

## VM-07

Resize/reflow stress test — thay đổi width/height và nội dung để kiểm tra reflow, overflow và breakpoint.

## VM-08

Localization stress test — thay bằng chuỗi dài, Vietnamese, CJK, RTL và tăng text size tới 200%.

## VM-09

Prototype walkthrough — chạy prototype và thực hiện tap, back, dismiss, swipe, drag, keyboard theo flow.

## VM-10

Accessibility inspection — kiểm tra role, accessible name, reading/focus order, announcement và touch target.

## VM-11

Duplicate/hash scan — chuẩn hóa nội dung rồi hash/so khớp để tìm duplicate hoặc near-duplicate.

## VM-12

Documentation/link audit — kiểm tra completeness, link, version, ví dụ và tính nhất quán của guideline.

## VM-13

Governance/changelog audit — kiểm tra owner, approval, version, changelog, migration và deprecation metadata.

## VM-14

Asset/export inspection — kiểm tra format, dimensions, ratio, export scale, source, license và fallback.

## VM-15

Motion/reduced-motion test — chạy transition ở normal/reduced motion và đối chiếu duration/easing tokens.
