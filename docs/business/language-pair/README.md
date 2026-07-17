# Language Pair business flows

Language Pair biểu diễn learning language và meaning/native language dùng làm context cho Deck. Object này không dịch card content và không quyết định hierarchy.

## Invariants

- Learning language và meaning language đều bắt buộc.
- Pair có identity ổn định; display label được tạo từ hai language names.
- Deck luôn tham chiếu một Pair hợp lệ.
- Nested Deck kế thừa Pair từ hierarchy; không có mixed-pair subtree.
- Xóa Pair không được tạo orphan Deck.
- Language name dài phải wrap; không ellipsis thông tin phân biệt.

## Flow catalog

| File | Flow sở hữu | Trạng thái |
| --- | --- | --- |
| [create-language-pair.md](./create-language-pair.md) | Tạo pair từ Settings hoặc first-run learning setup | Đã có |
| [edit-language-pair.md](./edit-language-pair.md) | Đổi learning/native language và review ảnh hưởng | Đã có |
| [select-language-pair.md](./select-language-pair.md) | Chọn pair khi tạo/move Deck | Đã có |
| [remove-language-pair.md](./remove-language-pair.md) | Guard Deck dependencies, confirm và remove | Đã có |

## Cross-object contracts

- Cung cấp `pair id + learning label + meaning label` cho Deck.
- Deck trả dependency count khi Edit/Remove cần impact summary.
- Flashcard giữ nguyên text khi Pair đổi; không auto-translate.
- First-run Create Deck dùng Create Pair contract nhưng sở hữu presentation tại `deck/create-deck.md`.

## Canonical state coverage

- List/one/empty/add/remove; validation; dependency blocked; submitting/failure/success.
- Long language names, multiple pairs, large font, narrow device, light/dark.
