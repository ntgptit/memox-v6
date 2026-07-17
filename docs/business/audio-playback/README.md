# Audio Playback business flows

Audio Playback sở hữu hands-free playback session cho một Deck/Card scope. Nó khác `flashcard/manage-card-audio.md`, nơi sở hữu audio asset/reference của từng Card.

## Invariants

- Playback queue là stable snapshot của eligible Cards/audio refs tại Start.
- Play/Pause/Seek/Next/Previous không update Learning Progress.
- Missing/broken audio không crash queue; skip/retry behavior rõ.
- Speed/voice preference không rewrite stored audio asset.
- App background/audio interruption giữ recoverable playback position theo platform policy.
- Finish Playback không được giả completed Study Session.

## Flow catalog

| File | Flow sở hữu | Trạng thái |
| --- | --- | --- |
| [start-deck-playback.md](./start-deck-playback.md) | Resolve scope/audio queue và bắt đầu Player | Đã có |
| [control-deck-playback.md](./control-deck-playback.md) | Play, pause, next, previous và position | Đã có |
| [change-playback-speed.md](./change-playback-speed.md) | Chọn speed và effective behavior | Đã có |
| [handle-audio-interruption.md](./handle-audio-interruption.md) | Background, call/headphone interruption và resume | Đã có |
| [recover-playback-error.md](./recover-playback-error.md) | Missing/broken asset, retry/skip và queue health | Đã có |
| [finish-deck-playback.md](./finish-deck-playback.md) | End state, replay, back to Deck | Đã có |

## Cross-object contracts

- Nhận Deck scope và eligible Card/audio snapshot từ Deck/Flashcard.
- Đọc voice/speed defaults từ Preferences.
- Không phát Attempt/Goal contribution trừ khi product sau này tạo explicit listening Study mode.
- Broken audio quản lý asset qua Flashcard Audio flow; Player chỉ recovery playback.

## Canonical state coverage

- Playing, paused, speed, error, end.
- Empty/no playable audio, minimum/dense queue, missing item, interruption/resume.
- Long Card text, lock/background, large font, narrow device, light/dark.
