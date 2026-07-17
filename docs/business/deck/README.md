# Deck business flows

Thư mục này là catalog các đặc tả nghiệp vụ liên quan đến vòng đời của Deck.

`create-deck.md` là tài liệu chuẩn tham chiếu về mức độ chi tiết và cách trình bày. Các file khác chỉ được xem là hoàn tất khi mô tả đầy đủ hành vi nghiệp vụ, trạng thái UI và acceptance criteria tương đương; không tạo file rỗng chỉ để giữ chỗ.

## 0. Canonical content-state contract

Mọi flow tạo, mở, thêm, di chuyển, xóa và import nội dung phải tuân theo bảng này. Trạng thái được suy ra từ nội dung hiện tại, không phải mode được lưu độc lập.

| Trạng thái | Điều kiện | Được phép | Không được phép |
| --- | --- | --- | --- |
| Empty Deck | Không có direct card, không có deck con | Tạo card đầu tiên hoặc tạo deck con đầu tiên | Chưa khóa loại nội dung |
| Deck-list mode / Parent | Có ít nhất một deck con, không có direct card | Tạo, mở, đổi tên, di chuyển, xóa deck con | Tạo direct card |
| Card-list mode / Leaf | Có ít nhất một direct card, không có deck con | Tạo, sửa, di chuyển, xóa card | Tạo deck con |
| Trở lại Empty | Xóa hoặc di chuyển hết toàn bộ nội dung hiện tại | Được chọn lại card hoặc deck làm loại nội dung đầu tiên | Không giữ mode cũ khi đã không còn nội dung |
| Mixed content | Có direct card và deck con cùng lúc | Không hợp lệ | Không render hoặc persist như trạng thái bình thường |
| Leaf → Parent conversion | Deck đang có card | Không được hỗ trợ trực tiếp | Không có `Organise into nested decks`; phải di chuyển/xóa hết card để Deck trở lại Empty trước |

Chi tiết phân loại và UI khi mở Deck nằm tại [open-deck.md](./open-deck.md); guard và chuyển trạng thái nằm tại [organise-deck.md](./organise-deck.md).

## 1. Danh sách tài liệu

### Core lifecycle

| Thứ tự | File | Flow sở hữu | Trạng thái |
| --- | --- | --- | --- |
| 1 | [create-deck.md](./create-deck.md) | Tạo Deck đầu tiên, root Deck, nested Deck và hành vi ngay sau khi tạo | Đã có |
| 2 | [open-deck.md](./open-deck.md) | Mở Deck và phân nhánh chính xác sang Empty, Leaf hoặc Parent theo nội dung hiện tại | Đã có |
| 3 | [edit-deck.md](./edit-deck.md) | Đổi tên, sửa description và xử lý draft/validation khi chỉnh metadata | Đã có |
| 4 | [organise-deck.md](./organise-deck.md) | Chọn loại nội dung đầu tiên, chặn mixed content và trở lại Empty khi nội dung cuối cùng không còn | Đã có |
| 5 | [move-deck.md](./move-deck.md) | Di chuyển Deck/nested Deck tới context hợp lệ, kiểm tra cycle, language pair và destination | Đã có |
| 6 | [delete-deck.md](./delete-deck.md) | Xóa Empty/Leaf/Parent Deck, cảnh báo ảnh hưởng, xác nhận và điều hướng sau khi xóa | Đã có |

### Content hierarchy and discovery

| Thứ tự | File | Flow sở hữu | Trạng thái |
| --- | --- | --- | --- |
| 7 | [browse-nested-decks.md](./browse-nested-decks.md) | Duyệt cây Deck, breadcrumb, deep nesting, danh sách child và quay lại đúng context | Đã có |
| 8 | [search-decks.md](./search-decks.md) | Tìm kiếm, lọc và chọn Deck tại Library hoặc trong Parent Deck | Đã có |
| 9 | [add-content-to-deck.md](./add-content-to-deck.md) | Chọn target khi Add Card/Import; Leaf và Empty hợp lệ, Parent bị chặn | Đã có |

### Cross-feature flows initiated from a Deck

| Thứ tự | File | Flow sở hữu | Trạng thái |
| --- | --- | --- | --- |
| 10 | [import-deck.md](./import-deck.md) | Import flat cards hoặc hierarchical content vào đúng loại Deck và xử lý preview/confirm | Đã có |
| 11 | [export-deck.md](./export-deck.md) | Chọn phạm vi Deck, export, chia sẻ file và xử lý failure/retry | Đã có |
| 12 | [study-deck.md](./study-deck.md) | Bắt đầu Study từ Leaf/Parent, tính aggregate scope và chặn khi không có card hợp lệ | Đã có |
| 13 | [reset-deck-progress.md](./reset-deck-progress.md) | Reset tiến độ học theo Deck, mô tả phạm vi descendant, xác nhận và khả năng phục hồi | Đã có |

Các file cross-feature chỉ đặc tả phần contract do Deck sở hữu: entry point, target/scope, eligibility, kết quả trả về và navigation. Chi tiết bên trong Card Editor, Import engine, Export engine hoặc Study session thuộc tài liệu của feature tương ứng và phải được dẫn chiếu, không sao chép.

## 2. Ranh giới để tránh trùng lặp

- `create-deck.md` sở hữu toàn bộ quy tắc tạo mới và hành vi ngay sau khi tạo thành công.
- `README.md` sở hữu canonical content-state contract áp dụng cho mọi Deck flow.
- `open-deck.md` sở hữu cách xác định Empty/Leaf/Parent mỗi lần mở hoặc refresh Deck và phải dẫn chiếu contract này.
- `organise-deck.md` sở hữu guard và các chuyển trạng thái hợp lệ sau khi Deck đã tồn tại; không sở hữu direct Leaf → Parent conversion vì flow đó không được hỗ trợ.
- `browse-nested-decks.md` sở hữu navigation trong cây; không sở hữu create, move hay delete.
- `add-content-to-deck.md` sở hữu điều kiện Deck có thể nhận card/import; không sở hữu form Card hoặc parser Import.
- `edit-deck.md`, `move-deck.md`, `delete-deck.md` là ba flow độc lập vì có validation, failure và hậu quả khác nhau.

Nếu một quy tắc ảnh hưởng nhiều flow, chỉ một file được chọn làm source of truth. Các file còn lại dẫn link tới quy tắc đó và chỉ mô tả phần thay đổi tại context của mình.

## 3. Tiêu chuẩn bắt buộc cho mỗi file

Mỗi đặc tả phải dùng cùng mức chi tiết với `create-deck.md` và tối thiểu có:

1. Phạm vi và các nguyên tắc đã chốt.
2. Objective và một primary outcome rõ ràng.
3. Phân loại entry point theo context.
4. Master flow bằng Mermaid.
5. Preconditions, eligibility và business invariants.
6. Composition cho từng surface chính; nêu rõ nội dung không được xuất hiện.
7. Field rules, validation và error copy nếu có input.
8. Submit/action lifecycle: idle, invalid, submitting, recoverable failure và success.
9. Cancel, Back, dismiss, draft retention và destructive confirmation.
10. Kết quả thành công, destination, highlight/snackbar/callout và các hành động không được tự động chạy.
11. State matrix gồm loading, normal/min/dense, empty, recoverable error, long text, large font, narrow device và dark mode.
12. Action visibility hoặc permission matrix khi hành động phụ thuộc loại Deck/context.
13. Acceptance criteria có thể kiểm chứng, bao gồm parity dưới 3% cho mọi canonical state × theme có UI reference.

## 4. Quy tắc đặt tên

- Dùng kebab-case: `<verb>-deck.md` hoặc `<verb>-decks.md`.
- Tên file phản ánh một flow nghiệp vụ, không dùng hậu tố `note`, `prompt`, `draft-final` hoặc tên màn hình kỹ thuật.
- Một file chỉ có một owner flow chính; các nhánh con được giữ chung khi cùng một transaction hoặc cùng một acceptance boundary.
