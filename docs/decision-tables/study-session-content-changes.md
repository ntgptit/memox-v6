# ST-CONTENT-CHANGE-v1 — Content change trong Study Session

Session snapshot là immutable learning input. Content mutation không sửa prompt/current queue im lặng.

| ID | Given | When | Then |
| --- | --- | --- | --- |
| ST-CHG-001 | Deck renamed/moved | Resume/return | Resolve bằng stable id, cập nhật display/path; snapshot không đổi |
| ST-CHG-002 | Deck deleted, snapshot content đủ | Continue | Cho hoàn tất snapshot; return Library |
| ST-CHG-003 | Card edited sau snapshot | Render prompt | Dùng content version trong snapshot; edit chỉ áp dụng session sau |
| ST-CHG-004 | Card moved sau snapshot | Continue | Giữ Card trong snapshot; return/aggregate dùng current stable id/path |
| ST-CHG-005 | Card hidden sau snapshot, chưa current | Advance | Skip với `reason=hiddenAfterSnapshot`; không giả correct/wrong |
| ST-CHG-006 | Card deleted sau snapshot, chưa current | Advance | Skip/tombstone với `reason=deletedAfterSnapshot`; không substitute |
| ST-CHG-007 | Card là current prompt/has pending answer | Delete requested | Block delete; yêu cầu exit/commit/skip explicit trước mutation |
| ST-CHG-008 | Attempt commit và delete race | Serialize | Một operation thắng theo version; loser nhận typed conflict/reload |
| ST-CHG-009 | Preferences changed | Resume | Giữ effective preference snapshot |
| ST-CHG-010 | Missing Card skip | Finalize | Exclude khỏi accuracy denominator, retain audit reason; không schedule |

Acceptance: delete, resume và answer flows cùng dùng bảng này; không có flow riêng được tự chọn `skip` hay `block` khác bảng.
