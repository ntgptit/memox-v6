# Mobile Design Kit Audit v5

Bản tái cấu trúc theo nguyên tắc:

- **Một file cho một nhóm KIT**: 48 nhóm, không tạo leaf giả.
- **Sáu mục đặc thù cho mỗi nhóm**: tổng 288 mục.
- Boilerplate quy trình nằm duy nhất trong `audit-rules.md`.
- Mỗi mục có **Cách kiểm** và **Evidence mong đợi**.
- KIT-08 chỉ audit contrast/non-color cues.
- Tablet/large screen thuộc KIT-32, không lặp trong KIT-11.
- Validation kiểm tra broken links, duplicate ID và duplicate/near-duplicate nội dung.
- Severity đã được phân tầng P0–P3 theo tác động phát hành.
- Tên file dùng slug ASCII chuẩn.
- Severity được hiệu chỉnh theo bản chất lỗi giữa các nhóm.
- Validator cảnh báo severity thấp cho accessible name, touch target và contrast.

## Đọc tiết kiệm token

Chỉ cần mở:

1. `audit-rules.md`
2. `verification-methods.md`
3. Một file `KIT-XX-*.md`
4. `issue-register.md` khi có lỗi

## Điều hướng

- [Audit Summary](./audit-summary.md)
- [Audit Rules](./audit-rules.md)
- [Verification Methods](./verification-methods.md)
- [Issue Register](./issue-register.md)
- [Validation Report](./validation-report.json)
- [Validation Script](./scripts/validate.py)

## Quy ước ngôn ngữ

Tài liệu sử dụng **song ngữ kỹ thuật có chủ đích**:

- Nội dung checklist, phạm vi, severity và quy tắc quản trị viết bằng tiếng Việt.
- `Cách kiểm` và `Evidence mong đợi` có thể viết hoàn toàn bằng tiếng Việt hoặc hoàn toàn bằng tiếng Anh kỹ thuật.
- Các thuật ngữ quen thuộc như token, component, state, theme, focus, dark mode, RTL và accessibility được giữ nguyên.
- Không chấp nhận câu hybrid do thay thế từng từ, ví dụ: `ràng buộc matrix and overflow báo cáo`.
- Không chấp nhận từ vỡ do ghép hậu tố tiếng Anh vào từ tiếng Việt, ví dụ: `ngoại lệs`.

Validator chỉ cảnh báo khi **một dòng có dấu tiếng Việt đồng thời chứa liên từ/mạo từ tiếng Anh**, hoặc có từ tiếng Việt bị dính hậu tố tiếng Anh.
