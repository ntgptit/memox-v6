# Preferences business flows

Preferences sở hữu lựa chọn cá nhân ảnh hưởng presentation và Study behavior. Nó không sở hữu Account identity, content hoặc recorded learning history.

## Invariants

- Mỗi preference có default rõ và backward-compatible khi key chưa tồn tại.
- Invalid/unknown persisted value fallback an toàn, không crash app.
- Theme/system choice áp dụng toàn app; không override cục bộ theo screen.
- Study preference mới áp dụng cho session mới trừ khi contract nói rõ.
- Thay đổi preference không rewrite completed attempts/progress.
- Restore defaults yêu cầu impact summary và explicit confirm khi nhiều nhóm bị reset.

## Flow catalog

| File | Flow sở hữu | Trạng thái |
| --- | --- | --- |
| [set-appearance-preference.md](./set-appearance-preference.md) | System/light/dark và supported appearance choices | Đã có |
| [configure-study-preferences.md](./configure-study-preferences.md) | SRS/session defaults áp dụng cho session mới | Đã có |
| [configure-word-display.md](./configure-word-display.md) | Meaning/gender/romanization display options | Đã có |
| [configure-mode-preferences.md](./configure-mode-preferences.md) | Mode availability/defaults và constraints | Đã có |
| [configure-voice-preferences.md](./configure-voice-preferences.md) | Voice/speed/audio defaults | Đã có |
| [restore-default-preferences.md](./restore-default-preferences.md) | Scope confirm, reset và recovery | Đã có |

## Cross-object contracts

- Study Session đọc effective preferences khi tạo snapshot.
- Flashcard/Player đọc display/voice preferences mà không persist chúng vào Card.
- Account Sync/Backup có thể transport preferences theo explicit compatibility contract.
- Design System sở hữu visual tokens; Preferences chỉ chọn supported mode.

## Canonical state coverage

- Defaults/custom/invalid fallback; picker/switch; saving/failure.
- System theme change, restore confirm, compatibility fallback.
- Long labels, large font, narrow device, light/dark.
