# Audit Rules

## Cách đánh dấu

- `[ ]`: Chưa kiểm tra hoặc chưa đạt.
- `[x]`: Đã kiểm tra, đạt tiêu chí và có evidence.
- Không dùng `[x]` cho trạng thái đạt một phần.

## Severity

| Severity | Gate |
|---|---|
| `P0` | Chặn phát hành |
| `P1` | Phải đóng trước khi chốt kit |
| `P2` | Có thể chấp nhận tạm; bắt buộc owner + target |
| `P3` | Cải tiến/cleanup |

## Nguyên tắc phân severity mặc định

- `P0`: Lỗi làm kit không thể phát hành an toàn hoặc khiến người dùng không thể hoàn thành tác vụ quan trọng.
- `P1`: Lỗi coverage, consistency hoặc behavior phải xử lý trước khi chốt kit.
- `P2`: Thiếu sót có thể chấp nhận có điều kiện khi đã có owner và target.
- `P3`: Polish, tối ưu hoặc tài liệu bổ sung không làm sai semantic/interaction cốt lõi.

Severity trong từng mục là **mặc định**. Auditor có thể nâng mức nếu phạm vi ảnh hưởng thực tế lớn hơn, nhưng phải ghi lý do trong issue.

## Điều kiện chung áp dụng một lần cho mỗi nhóm

Các điều kiện sau **không được nhân bản thành checkbox trong từng mục**:

1. Phạm vi nhóm được ghi rõ.
2. Mỗi issue có severity.
3. Mỗi issue có evidence.
4. P0/P1 có owner và target.
5. P2/P3 chưa đóng có owner và target.
6. Link evidence truy cập được.
7. Final status phản ánh đúng issue register.
8. Người kiểm tra và ngày kiểm tra được ghi.


## Quy tắc hiệu chỉnh severity giữa các nhóm

- Vi phạm cùng bản chất phải có cùng severity mặc định, bất kể nằm ở nhóm nào.
- Khi một yêu cầu xuất hiện ở nhiều nhóm với phạm vi chồng lấn, dùng severity cao nhất.
- Mục cấp component có thể thấp hơn mục end-to-end chỉ khi phạm vi ảnh hưởng thực sự nhỏ hơn và được giải thích.
- Các lỗi về accessible name, touch target và contrast không được đặt dưới `P1`.
- Nếu kết quả thực tế làm người dùng không thể hoàn thành tác vụ quan trọng, auditor phải nâng lên `P0`.
- Mọi thay đổi severity so với mặc định phải ghi lý do trong issue.


## Quy tắc ngôn ngữ kỹ thuật

- Một dòng phải là câu tiếng Việt rõ ràng hoặc câu tiếng Anh kỹ thuật hoàn chỉnh.
- Thuật ngữ kỹ thuật tiếng Anh được phép xuất hiện trong câu tiếng Việt.
- Không dịch bằng thay thế từng từ.
- Không để liên từ/mạo từ tiếng Anh nối các cụm tiếng Việt.
- Không để hậu tố tiếng Anh dính vào từ tiếng Việt.

## Cách sử dụng

1. Đọc `audit-rules.md`.
2. Đọc `verification-methods.md`.
3. Chỉ mở file `KIT-XX-*.md` đang audit.
4. Với mục đạt, đánh `[x]` và thêm link evidence vào Evidence Log.
5. Với mục không đạt, tạo issue trong `issue-register.md`.

## Evidence không hợp lệ

- “Đã kiểm tra”
- “Có vẻ ổn”
- “Đúng design”
- Screenshot không chỉ rõ artifact/version/state
- Link tới trang tổng không chỉ ra vị trí kiểm tra

## Hoàn thành nhóm

- Tất cả mục đã được kiểm tra.
- Không còn P0/P1.
- P2/P3 có owner và target.
- Evidence Log đủ để người khác tái kiểm tra.
